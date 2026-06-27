import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';

/// Result of a cloud synchronization run.
class SyncResult {
  const SyncResult({
    required this.success,
    this.syncedCategories = const [],
    this.failedCategories = const [],
    this.conflicts = const [],
    this.syncedAt,
    this.errorMessage,
    this.queuedWrites = 0,
  });

  final bool success;
  final List<SyncCategory> syncedCategories;
  final List<SyncCategory> failedCategories;
  final List<CloudConflict> conflicts;
  final DateTime? syncedAt;
  final String? errorMessage;
  final int queuedWrites;

  SyncResult copyWith({
    bool? success,
    List<SyncCategory>? syncedCategories,
    List<SyncCategory>? failedCategories,
    List<CloudConflict>? conflicts,
    DateTime? syncedAt,
    String? errorMessage,
    int? queuedWrites,
  }) {
    return SyncResult(
      success: success ?? this.success,
      syncedCategories: syncedCategories ?? this.syncedCategories,
      failedCategories: failedCategories ?? this.failedCategories,
      conflicts: conflicts ?? this.conflicts,
      syncedAt: syncedAt ?? this.syncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      queuedWrites: queuedWrites ?? this.queuedWrites,
    );
  }
}
