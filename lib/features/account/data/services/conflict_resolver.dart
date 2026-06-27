import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';

/// Reusable conflict resolution for cloud sync.
class ConflictResolver {
  const ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.newestWins,
  });

  final ConflictResolutionStrategy defaultStrategy;

  Map<String, dynamic> resolve({
    required CloudConflict conflict,
    ConflictResolutionStrategy? strategy,
    Map<String, dynamic>? manualPayload,
  }) {
    final chosen = strategy ?? defaultStrategy;
    return switch (chosen) {
      ConflictResolutionStrategy.newestWins =>
        conflict.remoteUpdatedAt.isAfter(conflict.localUpdatedAt)
            ? conflict.remotePayload
            : conflict.localPayload,
      ConflictResolutionStrategy.serverWins => conflict.remotePayload,
      ConflictResolutionStrategy.localWins => conflict.localPayload,
      ConflictResolutionStrategy.manual =>
        manualPayload ?? conflict.localPayload,
    };
  }

  CloudConflict markResolved(
    CloudConflict conflict,
    ConflictResolutionStrategy strategy,
  ) {
    return conflict.copyWith(
      resolvedStrategy: strategy,
      resolvedAt: DateTime.now(),
    );
  }
}
