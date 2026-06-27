import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Structured context bundle fed to the prompt builder.
///
/// The AI consumes this data — it never replaces routing or safety engines.
class AiContext {
  const AiContext({
    required this.mode,
    this.journey,
    this.route,
    this.session,
    this.safety,
    this.location,
    this.liveMetrics,
    this.averageSpeedKmh,
    this.driverScore,
    this.safetyScoreTrend,
    this.isOffline = false,
    this.weatherSummary,
    this.trafficSummary,
    this.emergencyTimelineEvents = const [],
    this.exploreRecommendations = const [],
    this.vehicleProfileSummary = const {},
    this.medicalProfileSummary = const {},
    this.includeMedicalProfile = false,
    this.userPreferences = const {},
  });

  final AiCopilotMode mode;
  final JourneySummary? journey;
  final RouteSummary? route;
  final NavigationSession? session;
  final SafetySnapshot? safety;
  final LocationPosition? location;
  final LiveJourneyMetrics? liveMetrics;
  final double? averageSpeedKmh;
  final double? driverScore;
  final String? safetyScoreTrend;
  final bool isOffline;
  final String? weatherSummary;
  final String? trafficSummary;
  final List<String> emergencyTimelineEvents;
  final List<String> exploreRecommendations;
  final Map<String, String> vehicleProfileSummary;
  final Map<String, String> medicalProfileSummary;
  final bool includeMedicalProfile;
  final Map<String, String> userPreferences;

  /// Cache key for reusable prompt context.
  String get cacheKey => [
        mode.name,
        journey?.destination.id,
        route?.id,
        session?.sessionId,
        safety?.assessment.timestamp.millisecondsSinceEpoch,
        isOffline,
      ].join('|');

  AiContext copyWith({
    JourneySummary? journey,
    RouteSummary? route,
    NavigationSession? session,
    SafetySnapshot? safety,
    LocationPosition? location,
    LiveJourneyMetrics? liveMetrics,
    double? averageSpeedKmh,
    double? driverScore,
    String? safetyScoreTrend,
    bool? isOffline,
    String? weatherSummary,
    String? trafficSummary,
    List<String>? emergencyTimelineEvents,
    List<String>? exploreRecommendations,
    Map<String, String>? vehicleProfileSummary,
    Map<String, String>? medicalProfileSummary,
    bool? includeMedicalProfile,
    Map<String, String>? userPreferences,
  }) =>
      AiContext(
        mode: mode,
        journey: journey ?? this.journey,
        route: route ?? this.route,
        session: session ?? this.session,
        safety: safety ?? this.safety,
        location: location ?? this.location,
        liveMetrics: liveMetrics ?? this.liveMetrics,
        averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
        driverScore: driverScore ?? this.driverScore,
        safetyScoreTrend: safetyScoreTrend ?? this.safetyScoreTrend,
        isOffline: isOffline ?? this.isOffline,
        weatherSummary: weatherSummary ?? this.weatherSummary,
        trafficSummary: trafficSummary ?? this.trafficSummary,
        emergencyTimelineEvents:
            emergencyTimelineEvents ?? this.emergencyTimelineEvents,
        exploreRecommendations:
            exploreRecommendations ?? this.exploreRecommendations,
        vehicleProfileSummary:
            vehicleProfileSummary ?? this.vehicleProfileSummary,
        medicalProfileSummary:
            medicalProfileSummary ?? this.medicalProfileSummary,
        includeMedicalProfile:
            includeMedicalProfile ?? this.includeMedicalProfile,
        userPreferences: userPreferences ?? this.userPreferences,
      );
}
