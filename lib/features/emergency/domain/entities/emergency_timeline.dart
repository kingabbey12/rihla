/// Timeline event types for emergency and journey review.
enum EmergencyTimelineEventType {
  journeyStarted,
  hazardDetected,
  safetyAlert,
  trafficEvent,
  emergencyTriggered,
  assistanceRequested,
  journeyEnded,
  incidentReported,
  sosSent,
  locationShared,
}

extension EmergencyTimelineEventTypeX on EmergencyTimelineEventType {
  String get displayName => switch (this) {
        EmergencyTimelineEventType.journeyStarted => 'Journey Started',
        EmergencyTimelineEventType.hazardDetected => 'Hazard Detected',
        EmergencyTimelineEventType.safetyAlert => 'Safety Alert',
        EmergencyTimelineEventType.trafficEvent => 'Traffic Event',
        EmergencyTimelineEventType.emergencyTriggered => 'Emergency Triggered',
        EmergencyTimelineEventType.assistanceRequested => 'Assistance Requested',
        EmergencyTimelineEventType.journeyEnded => 'Journey Ended',
        EmergencyTimelineEventType.incidentReported => 'Incident Reported',
        EmergencyTimelineEventType.sosSent => 'SOS Sent',
        EmergencyTimelineEventType.locationShared => 'Location Shared',
      };
}

/// A single event in the emergency timeline.
class EmergencyTimelineEvent {
  const EmergencyTimelineEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    this.metadata = const {},
  });

  final String id;
  final EmergencyTimelineEventType type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'metadata': metadata,
      };

  factory EmergencyTimelineEvent.fromJson(Map<String, dynamic> json) =>
      EmergencyTimelineEvent(
        id: json['id'] as String,
        type: EmergencyTimelineEventType.values
            .byName(json['type'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );
}

/// Chronological record of events for an incident or journey.
class EmergencyTimeline {
  const EmergencyTimeline({
    required this.id,
    required this.events,
    this.incidentId,
  });

  final String id;
  final String? incidentId;
  final List<EmergencyTimelineEvent> events;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (incidentId != null) 'incidentId': incidentId,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory EmergencyTimeline.fromJson(Map<String, dynamic> json) =>
      EmergencyTimeline(
        id: json['id'] as String,
        incidentId: json['incidentId'] as String?,
        events: (json['events'] as List<dynamic>)
            .map((e) => EmergencyTimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  EmergencyTimeline append(EmergencyTimelineEvent event) => EmergencyTimeline(
        id: id,
        incidentId: incidentId,
        events: [...events, event],
      );
}
