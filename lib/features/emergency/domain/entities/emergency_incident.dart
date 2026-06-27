import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_snapshots.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';

/// Status of an emergency incident.
enum EmergencyIncidentStatus {
  draft,
  pending,
  queued,
  submitted,
  resolved,
}

/// A reported emergency incident with full context.
class EmergencyIncident {
  const EmergencyIncident({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.timeline,
    this.snapshots,
    this.photoPaths = const [],
    this.videoPathPlaceholder,
    this.voiceNotePathPlaceholder,
    this.driverNotes,
    this.summary,
    this.syncedAt,
  });

  final String id;
  final EmergencyType type;
  final EmergencyIncidentStatus status;
  final EmergencyLocation location;
  final DateTime createdAt;
  final EmergencyTimeline timeline;
  final EmergencySnapshots? snapshots;
  final List<String> photoPaths;
  final String? videoPathPlaceholder;
  final String? voiceNotePathPlaceholder;
  final String? driverNotes;
  final String? summary;
  final DateTime? syncedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'location': location.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'timeline': timeline.toJson(),
        if (snapshots != null) 'snapshots': snapshots!.toJson(),
        'photoPaths': photoPaths,
        if (videoPathPlaceholder != null)
          'videoPathPlaceholder': videoPathPlaceholder,
        if (voiceNotePathPlaceholder != null)
          'voiceNotePathPlaceholder': voiceNotePathPlaceholder,
        if (driverNotes != null) 'driverNotes': driverNotes,
        if (summary != null) 'summary': summary,
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
      };

  factory EmergencyIncident.fromJson(Map<String, dynamic> json) =>
      EmergencyIncident(
        id: json['id'] as String,
        type: EmergencyType.values.byName(json['type'] as String),
        status: EmergencyIncidentStatus.values.byName(json['status'] as String),
        location: EmergencyLocation.fromJson(
          json['location'] as Map<String, dynamic>,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        timeline: EmergencyTimeline.fromJson(
          json['timeline'] as Map<String, dynamic>,
        ),
        snapshots: json['snapshots'] != null
            ? EmergencySnapshots.fromJson(
                json['snapshots'] as Map<String, dynamic>,
              )
            : null,
        photoPaths: (json['photoPaths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        videoPathPlaceholder: json['videoPathPlaceholder'] as String?,
        voiceNotePathPlaceholder: json['voiceNotePathPlaceholder'] as String?,
        driverNotes: json['driverNotes'] as String?,
        summary: json['summary'] as String?,
        syncedAt: json['syncedAt'] != null
            ? DateTime.parse(json['syncedAt'] as String)
            : null,
      );

  EmergencyIncident copyWith({
    EmergencyIncidentStatus? status,
    String? summary,
    List<String>? photoPaths,
    String? driverNotes,
    DateTime? syncedAt,
  }) =>
      EmergencyIncident(
        id: id,
        type: type,
        status: status ?? this.status,
        location: location,
        createdAt: createdAt,
        timeline: timeline,
        snapshots: snapshots,
        photoPaths: photoPaths ?? this.photoPaths,
        videoPathPlaceholder: videoPathPlaceholder,
        voiceNotePathPlaceholder: voiceNotePathPlaceholder,
        driverNotes: driverNotes ?? this.driverNotes,
        summary: summary ?? this.summary,
        syncedAt: syncedAt ?? this.syncedAt,
      );
}
