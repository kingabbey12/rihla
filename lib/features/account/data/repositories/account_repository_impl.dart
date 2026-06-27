import 'dart:convert';
import 'dart:io';

import 'package:rihla/features/account/data/datasources/account_local_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_secure_storage.dart';
import 'package:rihla/features/account/data/datasources/account_sync_queue_datasource.dart';
import 'package:rihla/features/account/data/services/cloud_data_collector.dart';
import 'package:rihla/features/account/data/services/cloud_sync_engine.dart';
import 'package:rihla/features/account/data/services/conflict_resolver.dart';
import 'package:rihla/features/account/domain/entities/auth_provider_type.dart';
import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/sync_result.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:rihla/features/account/domain/errors/account_failure.dart';
import 'package:rihla/features/account/domain/repositories/account_repository.dart';

/// Account repository — local-first with cloud sync via [CloudSyncEngine].
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountLocalDatasource local,
    required AccountRemoteDatasource remote,
    required AccountSyncQueueDatasource queue,
    required AccountSecureStorage secureStorage,
    required CloudDataCollector collector,
    required CloudDataApplier applier,
    bool Function()? isConnected,
    ConflictResolver? conflictResolver,
  })  : _local = local,
        _remote = remote,
        _queue = queue,
        _secure = secureStorage,
        _collector = collector,
        _applier = applier,
        _isConnected = isConnected ?? (() => true),
        _resolver = conflictResolver ?? const ConflictResolver() {
    _session = _local.getSession();
  }

  final AccountLocalDatasource _local;
  final AccountRemoteDatasource _remote;
  final AccountSyncQueueDatasource _queue;
  final AccountSecureStorage _secure;
  final CloudDataCollector _collector;
  final CloudDataApplier _applier;
  final bool Function() _isConnected;
  final ConflictResolver _resolver;

  AuthSession? _session;

  CloudSyncEngine get _engine => CloudSyncEngine(
        local: _local,
        remote: _remote,
        queue: _queue,
        collector: _collector,
        applier: _applier,
        conflictResolver: _resolver,
        isConnected: _isConnected(),
      );

  @override
  AuthSession? get currentSession => _session;

  Future<void> _persistSession(AuthSession session) async {
    _session = session;
    await _local.saveSession(session);
    if (session.accessToken != null) {
      await _secure.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    }
    await _local.saveSyncState(
      _local.getSyncState().copyWith(isSignedIn: !session.isGuest),
    );
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final session = await _remote.signInWithEmail(email, password);
    await _persistSession(session);
    await _registerCurrentDevice(session.userId);
    return session;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final session = await _remote.signUpWithEmail(
      email,
      password,
      displayName: displayName,
    );
    await _persistSession(session);
    await _registerCurrentDevice(session.userId);
    return session;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    final session = await _remote.signInWithOAuth('google');
    await _persistSession(
      session.copyWith(provider: AuthProviderType.google),
    );
    await _registerCurrentDevice(session.userId);
    return session;
  }

  @override
  Future<AuthSession> signInWithApple() async {
    final session = await _remote.signInWithOAuth('apple');
    await _persistSession(
      session.copyWith(provider: AuthProviderType.apple),
    );
    await _registerCurrentDevice(session.userId);
    return session;
  }

  @override
  Future<AuthSession> continueAsGuest() async {
    const session = AuthSession.guest;
    await _persistSession(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    if (_session != null && !_session!.isGuest) {
      await _remote.signOut();
    }
    await _secure.clearTokens();
    _session = null;
    await _local.saveSession(null);
    await _local.saveSyncState(CloudSyncState.initial);
  }

  @override
  Future<void> resetPassword(String email) => _remote.resetPassword(email);

  @override
  Future<void> sendEmailVerification() => _remote.sendEmailVerification();

  @override
  Future<AuthSession> refreshSession() async {
    final refresh = await _secure.getRefreshToken() ?? _session?.refreshToken;
    if (refresh == null) {
      throw const AccountAuthFailure('No refresh token');
    }
    final session = await _remote.refreshSession(refresh);
    await _persistSession(session);
    return session;
  }

  @override
  Future<AuthSession> upgradeGuestToEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_session == null || !_session!.isGuest) {
      throw const AccountAuthFailure('Not in guest mode');
    }
    final session = await signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    await syncAll(force: true);
    return session;
  }

  @override
  Future<UserProfile> getProfile() async {
    if (_session == null || _session!.isGuest) {
      return _local.getProfile();
    }
    try {
      final remote = await _remote.fetchProfile(_session!.userId);
      if (!remote.isEmpty) {
        await _local.saveProfile(remote);
        return remote;
      }
    } catch (_) {}
    return _local.getProfile();
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _local.saveProfile(updated);
    if (_session != null && !_session!.isGuest) {
      await _remote.upsertProfile(_session!.userId, updated);
    }
    return updated;
  }

  @override
  Future<UserPreferences> getPreferences() async {
    if (_session == null || _session!.isGuest) {
      return _local.getPreferences();
    }
    try {
      final remote = await _remote.fetchPreferences(_session!.userId);
      await _local.savePreferences(remote);
      return remote;
    } catch (_) {
      return _local.getPreferences();
    }
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final updated = preferences.copyWith(updatedAt: DateTime.now());
    await _local.savePreferences(updated);
    if (_session != null && !_session!.isGuest) {
      await _remote.upsertPreferences(_session!.userId, updated);
    }
    return updated;
  }

  @override
  Future<SyncPrivacySettings> getSyncPrivacySettings() =>
      Future.value(_local.getPrivacySettings());

  @override
  Future<SyncPrivacySettings> updateSyncPrivacySettings(
    SyncPrivacySettings settings,
  ) async {
    await _local.savePrivacySettings(settings);
    return settings;
  }

  @override
  Future<CloudSyncState> getSyncState() async {
    final state = _local.getSyncState();
    return state.copyWith(
      pendingWrites: _queue.getQueue().length,
      conflictCount: _local.getConflicts().length,
      isSignedIn: _session != null && !_session!.isGuest,
    );
  }

  @override
  Future<SyncResult> syncAll({bool force = false}) async {
    if (_session == null || _session!.isGuest) {
      return const SyncResult(success: true);
    }
    if (!_isConnected()) {
      return SyncResult(
        success: false,
        errorMessage: 'Offline',
        queuedWrites: _queue.getQueue().length,
      );
    }
    return _engine.synchronizeAll(
      userId: _session!.userId,
      privacy: _local.getPrivacySettings(),
    );
  }

  @override
  Future<SyncResult> syncCategory(SyncCategory category) async {
    if (_session == null || _session!.isGuest) {
      return const SyncResult(success: true);
    }
    return _engine.synchronizeCategory(
      userId: _session!.userId,
      category: category,
      privacy: _local.getPrivacySettings(),
    );
  }

  @override
  Future<List<CloudConflict>> getConflicts() async =>
      _local.getConflicts();

  @override
  Future<void> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? manualPayload,
  }) async {
    final conflicts = _local.getConflicts();
    final conflict = conflicts.firstWhere(
      (c) => c.id == conflictId,
      orElse: () => throw AccountConflictFailure('Conflict not found'),
    );
    final resolved = _resolver.resolve(
      conflict: conflict,
      strategy: strategy,
      manualPayload: manualPayload,
    );
    await _applier.apply(conflict.category, resolved);
    if (_session != null && !_session!.isGuest) {
      await _remote.upsertCategory(
        _session!.userId,
        RemoteSyncPayload(
          category: conflict.category,
          data: resolved,
          updatedAt: DateTime.now(),
        ),
      );
    }
    final updatedConflicts = conflicts
        .map(
          (c) => c.id == conflictId
              ? _resolver.markResolved(c, strategy)
              : c,
        )
        .where((c) => !c.isResolved)
        .toList();
    await _local.saveConflicts(updatedConflicts);
  }

  @override
  Future<List<ConnectedDevice>> getConnectedDevices() async {
    if (_session == null || _session!.isGuest) {
      return _local.getDevices();
    }
    try {
      final remote = await _remote.fetchDevices(_session!.userId);
      await _local.saveDevices(remote);
      return remote;
    } catch (_) {
      return _local.getDevices();
    }
  }

  @override
  Future<String> exportUserData() async {
    final buffer = StringBuffer('{"exportedAt":"${DateTime.now().toIso8601String()}"');
    buffer.write(',"profile":${jsonEncode((await getProfile()).toJson())}');
    buffer.write(',"preferences":${jsonEncode((await getPreferences()).toJson())}');
    buffer.write(',"privacy":${jsonEncode(_local.getPrivacySettings().toJson())}');
    for (final category in SyncCategory.values) {
      final data = _collector.collect(category);
      buffer.write(',"${category.name}":${jsonEncode(data)}');
    }
    if (_session != null && !_session!.isGuest) {
      try {
        final remote = await _remote.exportRemoteData(_session!.userId);
        buffer.write(',"remote":${jsonEncode(remote)}');
      } catch (_) {}
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  Future<void> deleteAccount() async {
    if (_session == null || _session!.isGuest) {
      await _local.clearAll();
      await _secure.clearAll();
      _session = null;
      return;
    }
    await _remote.deleteAccount(_session!.userId);
    await _local.clearAll();
    await _secure.clearAll();
    await _queue.clear();
    _session = null;
  }

  @override
  Future<void> enqueueWrite(
    SyncCategory category,
    Map<String, dynamic> payload,
  ) async {
    await _queue.enqueue(
      QueuedSyncWrite(
        id: '${category.name}_${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        payload: payload,
        queuedAt: DateTime.now(),
      ),
    );
    await _local.saveSyncState(
      _local.getSyncState().copyWith(
        pendingWrites: _queue.getQueue().length,
      ),
    );
  }

  @override
  Future<SyncResult> flushQueue() async {
    if (_session == null || _session!.isGuest) {
      return const SyncResult(success: true);
    }
    return _engine.flushQueue(
      userId: _session!.userId,
      privacy: _local.getPrivacySettings(),
    );
  }

  Future<void> _registerCurrentDevice(String userId) async {
    final device = ConnectedDevice(
      id: '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}',
      name: Platform.localHostname,
      platform: Platform.operatingSystem,
      lastSeenAt: DateTime.now(),
      isCurrent: true,
    );
    await _local.saveDevices([device]);
    if (!_session!.isGuest) {
      try {
        await _remote.registerDevice(userId, device);
      } catch (_) {}
    }
  }
}
