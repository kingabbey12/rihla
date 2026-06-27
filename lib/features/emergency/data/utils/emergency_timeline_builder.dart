import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Builds emergency timelines from journey and safety events.
abstract final class EmergencyTimelineBuilder {
  static EmergencyTimelineEvent journeyStarted({
    required String destination,
    required DateTime timestamp,
  }) =>
      EmergencyTimelineEvent(
        id: 'tl_journey_start_${timestamp.millisecondsSinceEpoch}',
        type: EmergencyTimelineEventType.journeyStarted,
        timestamp: timestamp,
        description: 'Journey started to $destination',
        metadata: {'destination': destination},
      );

  static EmergencyTimelineEvent journeyEnded({required DateTime timestamp}) =>
      EmergencyTimelineEvent(
        id: 'tl_journey_end_${timestamp.millisecondsSinceEpoch}',
        type: EmergencyTimelineEventType.journeyEnded,
        timestamp: timestamp,
        description: 'Journey ended',
      );

  static List<EmergencyTimelineEvent> fromSafetySnapshot(
    SafetySnapshot snapshot,
    DateTime timestamp,
  ) {
    final events = <EmergencyTimelineEvent>[];
    for (final hazard in snapshot.hazards) {
      events.add(
        EmergencyTimelineEvent(
          id: 'tl_hazard_${hazard.id}',
          type: EmergencyTimelineEventType.hazardDetected,
          timestamp: timestamp,
          description: hazard.description,
          metadata: {'severity': hazard.severity.name},
        ),
      );
    }
    if (snapshot.primaryAlert != null) {
      events.add(
        EmergencyTimelineEvent(
          id: 'tl_alert_${timestamp.millisecondsSinceEpoch}',
          type: EmergencyTimelineEventType.safetyAlert,
          timestamp: timestamp,
          description: snapshot.primaryAlert!.title,
        ),
      );
    }
    return events;
  }
}
