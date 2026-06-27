import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';

/// A single beta feedback submission stored locally until synced.
class BetaFeedback {
  const BetaFeedback({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.rating,
    this.screenshotPath,
    this.includeDiagnostics = false,
    this.diagnostics = const {},
    this.synced = false,
  });

  final String id;
  final BetaFeedbackType type;
  final String message;
  final int? rating;
  final String? screenshotPath;
  final bool includeDiagnostics;
  final Map<String, String> diagnostics;
  final DateTime createdAt;
  final bool synced;

  BetaFeedback copyWith({
    String? id,
    BetaFeedbackType? type,
    String? message,
    int? rating,
    String? screenshotPath,
    bool? includeDiagnostics,
    Map<String, String>? diagnostics,
    DateTime? createdAt,
    bool? synced,
  }) =>
      BetaFeedback(
        id: id ?? this.id,
        type: type ?? this.type,
        message: message ?? this.message,
        rating: rating ?? this.rating,
        screenshotPath: screenshotPath ?? this.screenshotPath,
        includeDiagnostics: includeDiagnostics ?? this.includeDiagnostics,
        diagnostics: diagnostics ?? this.diagnostics,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wireName,
        'message': message,
        'rating': rating,
        'screenshotPath': screenshotPath,
        'includeDiagnostics': includeDiagnostics,
        'diagnostics': diagnostics,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory BetaFeedback.fromJson(Map<String, dynamic> json) => BetaFeedback(
        id: json['id'] as String,
        type: BetaFeedbackType.values.firstWhere(
          (t) => t.wireName == json['type'],
          orElse: () => BetaFeedbackType.bugReport,
        ),
        message: json['message'] as String,
        rating: json['rating'] as int?,
        screenshotPath: json['screenshotPath'] as String?,
        includeDiagnostics: json['includeDiagnostics'] as bool? ?? false,
        diagnostics: Map<String, String>.from(
          (json['diagnostics'] as Map<String, dynamic>?) ?? {},
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );
}
