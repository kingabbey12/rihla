import 'package:rihla/features/account/data/datasources/account_local_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_sync_queue_datasource.dart';
import 'package:rihla/features/account/data/services/cloud_data_collector.dart';
import 'package:rihla/features/account/data/services/conflict_resolver.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/sync_result.dart';

/// Orchestrates bidirectional cloud synchronization.
class CloudSyncEngine {
  CloudSyncEngine({
    required AccountLocalDatasource local,
    required AccountRemoteDatasource remote,
    required AccountSyncQueueDatasource queue,
    required CloudDataCollector collector,
    required CloudDataApplier applier,
    ConflictResolver? conflictResolver,
    this.isConnected = true,
  })  : _local = local,
        _remote = remote,
        _queue = queue,
        _collector = collector,
        _applier = applier,
        _resolver = conflictResolver ?? const ConflictResolver();

  final AccountLocalDatasource _local;
  final AccountRemoteDatasource _remote;
  final AccountSyncQueueDatasource _queue;
  final CloudDataCollector _collector;
  final CloudDataApplier _applier;
  final ConflictResolver _resolver;
  final bool isConnected;

  Future<SyncResult> synchronizeAll({
    required String userId,
    required SyncPrivacySettings privacy,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.newestWins,
  }) async {
    if (!isConnected) {
      return SyncResult(
        success: false,
        errorMessage: 'Offline — writes queued',
        queuedWrites: _queue.getQueue().length,
      );
    }

    final synced = <SyncCategory>[];
    final failed = <SyncCategory>[];
    final conflicts = <CloudConflict>[];

    await _local.saveSyncState(
      _local.getSyncState().copyWith(status: CloudSyncStatus.syncing),
    );

    for (final category in SyncCategory.values) {
      if (!privacy.isEnabled(category)) continue;
      try {
        final result = await _syncCategory(
          userId: userId,
          category: category,
          strategy: strategy,
        );
        if (result.conflict != null) {
          conflicts.add(result.conflict!);
        } else {
          synced.add(category);
        }
      } catch (_) {
        failed.add(category);
      }
    }

    final queueResult = await flushQueue(userId: userId, privacy: privacy);
    final allConflicts = [...conflicts, ...queueResult.conflicts];

    var storageBytes = 0;
    for (final c in synced) {
      storageBytes += await _collector.estimatePayloadBytes(c);
    }

    await _local.saveSyncState(
      CloudSyncState(
        status: allConflicts.isEmpty
            ? CloudSyncStatus.idle
            : CloudSyncStatus.conflict,
        lastSyncAt: DateTime.now(),
        conflictCount: allConflicts.length,
        pendingWrites: _queue.getQueue().length,
        storageUsedBytes: storageBytes,
        isSignedIn: true,
      ),
    );
    if (allConflicts.isNotEmpty) {
      await _local.saveConflicts([
        ..._local.getConflicts(),
        ...allConflicts,
      ]);
    }

    return SyncResult(
      success: failed.isEmpty,
      syncedCategories: synced,
      failedCategories: failed,
      conflicts: allConflicts,
      syncedAt: DateTime.now(),
      queuedWrites: _queue.getQueue().length,
    );
  }

  Future<SyncResult> synchronizeCategory({
    required String userId,
    required SyncCategory category,
    required SyncPrivacySettings privacy,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.newestWins,
  }) async {
    if (!privacy.isEnabled(category)) {
      return const SyncResult(success: true, syncedCategories: []);
    }
    if (!isConnected) {
      return SyncResult(
        success: false,
        errorMessage: 'Offline',
        queuedWrites: _queue.getQueue().length,
      );
    }

    final result = await _syncCategory(
      userId: userId,
      category: category,
      strategy: strategy,
    );
    return SyncResult(
      success: result.conflict == null,
      syncedCategories: result.conflict == null ? [category] : [],
      conflicts: result.conflict != null ? [result.conflict!] : [],
      syncedAt: DateTime.now(),
    );
  }

  Future<SyncResult> flushQueue({
    required String userId,
    required SyncPrivacySettings privacy,
  }) async {
    if (!isConnected) {
      return SyncResult(
        success: false,
        queuedWrites: _queue.getQueue().length,
      );
    }

    final synced = <SyncCategory>[];
    final conflicts = <CloudConflict>[];

    for (final write in _queue.getQueue()) {
      if (!privacy.isEnabled(write.category)) continue;
      try {
        await _remote.upsertCategory(
          userId,
          RemoteSyncPayload(
            category: write.category,
            data: write.payload,
            updatedAt: DateTime.now(),
          ),
        );
        await _queue.remove(write.id);
        synced.add(write.category);
      } catch (_) {
        // keep in queue
      }
    }

    return SyncResult(
      success: conflicts.isEmpty,
      syncedCategories: synced,
      conflicts: conflicts,
      syncedAt: DateTime.now(),
      queuedWrites: _queue.getQueue().length,
    );
  }

  Future<_CategorySyncResult> _syncCategory({
    required String userId,
    required SyncCategory category,
    required ConflictResolutionStrategy strategy,
  }) async {
    final localData = await _collector.collect(category);
    final localUpdated = _collector.localUpdatedAt(category);
    final remote = await _remote.fetchCategory(userId, category);

    if (remote == null) {
      await _remote.upsertCategory(
        userId,
        RemoteSyncPayload(
          category: category,
          data: localData,
          updatedAt: localUpdated == DateTime.fromMillisecondsSinceEpoch(0)
              ? DateTime.now()
              : localUpdated,
        ),
      );
      return const _CategorySyncResult();
    }

    if (_payloadsEqual(localData, remote.data)) {
      return const _CategorySyncResult();
    }

    if (localUpdated.isAtSameMomentAs(remote.updatedAt) ||
        localUpdated == DateTime.fromMillisecondsSinceEpoch(0)) {
      await _applier.apply(category, remote.data);
      return const _CategorySyncResult();
    }

    if (localUpdated.isAfter(remote.updatedAt)) {
      await _remote.upsertCategory(
        userId,
        RemoteSyncPayload(
          category: category,
          data: localData,
          updatedAt: localUpdated,
        ),
      );
      return const _CategorySyncResult();
    }

    if (remote.updatedAt.isAfter(localUpdated)) {
      final conflict = CloudConflict(
        id: '${category.name}_${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        localUpdatedAt: localUpdated,
        remoteUpdatedAt: remote.updatedAt,
        localPayload: localData,
        remotePayload: remote.data,
      );
      final resolved = _resolver.resolve(
        conflict: conflict,
        strategy: strategy,
      );
      await _applier.apply(category, resolved);
      await _remote.upsertCategory(
        userId,
        RemoteSyncPayload(
          category: category,
          data: resolved,
          updatedAt: DateTime.now(),
        ),
      );
      if (strategy == ConflictResolutionStrategy.manual) {
        return _CategorySyncResult(conflict: conflict);
      }
    }

    return const _CategorySyncResult();
  }

  bool _payloadsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a.toString() == b.toString();
  }
}

class _CategorySyncResult {
  const _CategorySyncResult({this.conflict});
  final CloudConflict? conflict;
}
