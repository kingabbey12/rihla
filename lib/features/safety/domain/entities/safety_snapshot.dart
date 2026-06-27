import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';

/// Safety state attached to an active navigation session.
class SafetySnapshot {
  const SafetySnapshot({
    required this.assessment,
    required this.hazards,
    this.primaryAlert,
  });

  final SafetyAssessment assessment;
  final List<Hazard> hazards;

  /// Nearest highest-severity active hazard, if any.
  final Hazard? primaryAlert;

  static SafetySnapshot initial() => SafetySnapshot(
        assessment: SafetyAssessment.neutral(),
        hazards: const [],
      );

  SafetySnapshot copyWith({
    SafetyAssessment? assessment,
    List<Hazard>? hazards,
    Hazard? primaryAlert,
    bool clearPrimaryAlert = false,
  }) {
    return SafetySnapshot(
      assessment: assessment ?? this.assessment,
      hazards: hazards ?? this.hazards,
      primaryAlert: clearPrimaryAlert ? null : (primaryAlert ?? this.primaryAlert),
    );
  }
}
