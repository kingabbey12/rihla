import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';

/// A sync conflict between local and remote data.
class CloudConflict {
  const CloudConflict({
    required this.id,
    required this.category,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    this.localPayload = const {},
    this.remotePayload = const {},
    this.resolvedStrategy,
    this.resolvedAt,
  });

  final String id;
  final SyncCategory category;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final ConflictResolutionStrategy? resolvedStrategy;
  final DateTime? resolvedAt;

  bool get isResolved => resolvedStrategy != null;

  CloudConflict copyWith({
    ConflictResolutionStrategy? resolvedStrategy,
    DateTime? resolvedAt,
  }) {
    return CloudConflict(
      id: id,
      category: category,
      localUpdatedAt: localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
      localPayload: localPayload,
      remotePayload: remotePayload,
      resolvedStrategy: resolvedStrategy ?? this.resolvedStrategy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'localUpdatedAt': localUpdatedAt.toIso8601String(),
        'remoteUpdatedAt': remoteUpdatedAt.toIso8601String(),
        'localPayload': localPayload,
        'remotePayload': remotePayload,
        'resolvedStrategy': resolvedStrategy?.name,
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory CloudConflict.fromJson(Map<String, dynamic> json) {
    return CloudConflict(
      id: json['id'] as String,
      category: SyncCategory.values.firstWhere(
        (c) => c.name == json['category'],
      ),
      localUpdatedAt: DateTime.parse(json['localUpdatedAt'] as String),
      remoteUpdatedAt: DateTime.parse(json['remoteUpdatedAt'] as String),
      localPayload: Map<String, dynamic>.from(
        json['localPayload'] as Map? ?? {},
      ),
      remotePayload: Map<String, dynamic>.from(
        json['remotePayload'] as Map? ?? {},
      ),
      resolvedStrategy: json['resolvedStrategy'] != null
          ? ConflictResolutionStrategy.values.firstWhere(
              (s) => s.name == json['resolvedStrategy'],
            )
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}
