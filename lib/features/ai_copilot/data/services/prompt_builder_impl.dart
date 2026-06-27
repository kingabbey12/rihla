import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/models/prompt_package.dart';
import 'package:rihla/features/ai_copilot/domain/services/prompt_builder.dart';

/// Central prompt assembly — no string concatenation elsewhere in the app.
class PromptBuilderImpl implements PromptBuilder {
  static const safetyRules = '''
SAFETY RULES (mandatory):
- You are advisory only. Never override navigation, reroute automatically, contact emergency services, send messages, or share medical data without explicit user confirmation.
- Never invent routes, safety scores, or hazard data — use only structured context provided.
- Recommendations must be suggestions the driver can accept or ignore.
''';

  static const outputFormat = '''
OUTPUT FORMAT (mandatory):
SUMMARY: <one paragraph>
HIGHLIGHT: <bullet point>
REC:type|title|body|priority|actionable
Valid REC types: departure, route, safety, traffic, fuel, battery, driving, improvement, general
''';

  @override
  PromptPackage build(AiContext context, {AiConversation? conversation}) {
    final toolOutputs = _toolOutputsFrom(context);
    return PromptPackage(
      mode: context.mode,
      systemPrompt: '${_systemPrompt(context.mode)}\n$safetyRules\n$outputFormat',
      userPrompt: _userPrompt(context, conversation),
      toolOutputs: toolOutputs,
    );
  }

  String _systemPrompt(AiCopilotMode mode) {
    return switch (mode) {
      AiCopilotMode.journeyAdvisor => '''
You are Rihla Journey Advisor. Summarize the planned journey using only the structured context provided.
Never compute routes or safety scores — those come from dedicated engines.
Recommend departure timing and route profile when data is available.
Respond with concise, actionable advice for the driver before navigation starts.
''',
      AiCopilotMode.drivingCopilot => '''
You are Rihla Driving Copilot. Explain hazards, traffic, road changes, score shifts, and safety alerts during active navigation.
Never replace the routing or safety engines — interpret their outputs only.
Offer reroute recommendations when traffic or hazards warrant it — user must confirm any route change.
Use UAE-specific context (Salik, cameras, emirate rules, weather) when provided in structured data.
Keep guidance brief and safety-focused.
''',
      AiCopilotMode.journeyReview => '''
You are Rihla Journey Review. Summarize the completed trip using structured metrics only.
Highlight duration, distance, average speed, safety trend, traffic, fuel, battery, and driver score.
Suggest concrete improvements for the next journey.
''',
    };
  }

  String _userPrompt(AiContext context, AiConversation? conversation) {
    final buffer = StringBuffer();
    buffer.writeln('mode: ${context.mode.name}');
    if (context.isOffline) {
      buffer.writeln('offline: true');
    }
    buffer.writeln('---');

    if (conversation != null && conversation.messages.isNotEmpty) {
      buffer.writeln('[conversation_history]');
      for (final msg in conversation.messages.take(6)) {
        buffer.writeln('${msg.role.name}: ${msg.content}');
      }
      buffer.writeln('---');
    }

    final journey = context.journey;
    if (journey != null) {
      buffer.writeln('[journey]');
      buffer.writeln('destination: ${journey.destination.name}');
      buffer.writeln('origin: ${journey.origin.name}');
      buffer.writeln('journey_score: ${journey.score.journeyScore}');
      buffer.writeln('safety_score: ${journey.score.safetyScore}');
      buffer.writeln('distance_km: ${journey.metrics.distanceKm}');
      buffer.writeln('duration_min: ${journey.metrics.durationMinutes}');
      buffer.writeln('weather: ${journey.metrics.weatherSummary}');
      buffer.writeln('temperature_c: ${journey.metrics.temperatureCelsius}');
      buffer.writeln('traffic: ${journey.metrics.trafficLevel.name}');
      buffer.writeln('fuel_l: ${journey.metrics.fuelEstimateLiters}');
      buffer.writeln('battery_pct: ${journey.metrics.batteryEstimatePercent}');
      buffer.writeln('road: ${journey.metrics.roadCondition.name}');
      if (journey.metrics.departureSuggestions.isNotEmpty) {
        buffer.writeln(
          'departure_suggestions: ${journey.metrics.departureSuggestions.join('; ')}',
        );
      }
      buffer.writeln('---');
    }

    final route = context.route;
    if (route != null) {
      buffer.writeln('[route]');
      buffer.writeln('profile: ${route.profile.name}');
      buffer.writeln('distance_km: ${route.distanceKm}');
      buffer.writeln('duration_min: ${route.durationMinutes}');
      buffer.writeln('journey_score: ${route.journeyScore}');
      buffer.writeln('fuel_l: ${route.fuelEstimateLiters}');
      buffer.writeln('traffic: ${route.trafficSummary}');
      buffer.writeln('safety: ${route.safetySummary}');
      buffer.writeln('---');
    }

    final session = context.session;
    if (session != null) {
      buffer.writeln('[navigation]');
      buffer.writeln('session_id: ${session.sessionId}');
      buffer.writeln('road: ${session.currentRoad}');
      buffer.writeln('speed_kmh: ${session.speedKmh}');
      buffer.writeln('remaining_km: ${session.remainingDistanceKm}');
      buffer.writeln('progress_pct: ${session.routeProgressPercent}');
      buffer.writeln('off_route: ${session.isOffRoute}');
      buffer.writeln('maneuver: ${session.currentManeuver.instruction}');
      buffer.writeln('---');
    }

    final safety = context.safety;
    if (safety != null) {
      final a = safety.assessment;
      buffer.writeln('[safety]');
      buffer.writeln('overall: ${a.overallSafetyScore}');
      buffer.writeln('road: ${a.roadSafety}');
      buffer.writeln('traffic_risk: ${a.trafficRisk}');
      buffer.writeln('weather_risk: ${a.weatherRisk}');
      buffer.writeln('driver_alertness: ${a.driverAlertness}');
      buffer.writeln('vehicle_readiness: ${a.vehicleReadiness}');
      buffer.writeln('journey_risk: ${a.journeyRisk}');
      if (safety.hazards.isNotEmpty) {
        buffer.writeln('hazards:');
        for (final h in safety.hazards.take(5)) {
          buffer.writeln(
            '  - ${h.type.name} (${h.severity.name}): ${h.title} @ ${h.distanceAheadKm.toStringAsFixed(1)} km',
          );
        }
      }
      if (safety.primaryAlert != null) {
        buffer.writeln('primary_alert: ${safety.primaryAlert!.title}');
      }
      buffer.writeln('---');
    }

    if (context.emergencyTimelineEvents.isNotEmpty) {
      buffer.writeln('[emergency_timeline]');
      for (final event in context.emergencyTimelineEvents) {
        buffer.writeln('  - $event');
      }
      buffer.writeln('---');
    }

    if (context.exploreRecommendations.isNotEmpty) {
      buffer.writeln('[explore_recommendations]');
      for (final rec in context.exploreRecommendations) {
        buffer.writeln('  - $rec');
      }
      buffer.writeln('---');
    }

    if (context.vehicleProfileSummary.isNotEmpty) {
      buffer.writeln('[vehicle_profile]');
      context.vehicleProfileSummary.forEach((k, v) {
        buffer.writeln('$k: $v');
      });
      buffer.writeln('---');
    }

    if (context.includeMedicalProfile &&
        context.medicalProfileSummary.isNotEmpty) {
      buffer.writeln('[medical_profile]');
      context.medicalProfileSummary.forEach((k, v) {
        buffer.writeln('$k: $v');
      });
      buffer.writeln('---');
    }

    if (context.userPreferences.isNotEmpty) {
      buffer.writeln('[user_preferences]');
      context.userPreferences.forEach((k, v) {
        buffer.writeln('$k: $v');
      });
      buffer.writeln('---');
    }

    if (context.uaeIntelligenceSummary.isNotEmpty) {
      buffer.writeln('[uae_intelligence]');
      context.uaeIntelligenceSummary.forEach((k, v) {
        buffer.writeln('$k: $v');
      });
      buffer.writeln('---');
    }

    final live = context.liveMetrics;
    if (live != null) {
      buffer.writeln('[live_metrics]');
      buffer.writeln('journey_score: ${live.journeyScore.value}');
      buffer.writeln('safety_score: ${live.safetyScore.value}');
      buffer.writeln('traffic_score: ${live.trafficScore.value}');
      buffer.writeln('weather: ${live.weather.value}');
      buffer.writeln('road: ${live.roadCondition.value}');
      buffer.writeln('speed_kmh: ${live.currentSpeedKmh.value}');
      buffer.writeln('fuel_l: ${live.fuelEstimateLiters.value}');
      buffer.writeln('battery_pct: ${live.batteryEstimatePercent.value}');
      buffer.writeln('---');
    }

    if (context.averageSpeedKmh != null) {
      buffer.writeln('[review]');
      buffer.writeln('average_speed_kmh: ${context.averageSpeedKmh}');
      buffer.writeln('driver_score: ${context.driverScore}');
      buffer.writeln('safety_trend: ${context.safetyScoreTrend}');
      if (session != null) {
        final elapsed = DateTime.now().difference(session.startedAt);
        buffer.writeln('duration_min: ${elapsed.inMinutes}');
        buffer.writeln('distance_km: ${session.distanceTraveledKm}');
      }
    }

    final location = context.location;
    if (location != null) {
      buffer.writeln('[location]');
      buffer.writeln('lat: ${location.latitude}');
      buffer.writeln('lng: ${location.longitude}');
      buffer.writeln('accuracy_m: ${location.accuracy}');
    }

    return buffer.toString();
  }

  List<String> _toolOutputsFrom(AiContext context) {
    final outputs = <String>[];
    if (context.safety != null) {
      outputs.add(
        'safety_engine: ${context.safety!.assessment.overallSafetyScore}',
      );
    }
    if (context.route != null) {
      outputs.add('route_engine: ${context.route!.id}');
    }
    if (context.liveMetrics != null) {
      outputs.add('live_metrics: tick');
    }
    if (context.isOffline) {
      outputs.add('offline_state: active');
    }
    return outputs;
  }
}
