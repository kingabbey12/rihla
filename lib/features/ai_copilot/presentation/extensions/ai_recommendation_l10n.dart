import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';

extension AiRecommendationL10n on AiRecommendationType {
  IconData get icon => switch (this) {
        AiRecommendationType.departure => Icons.schedule,
        AiRecommendationType.route => Icons.alt_route,
        AiRecommendationType.reroute => Icons.turn_right,
        AiRecommendationType.safety => Icons.shield_outlined,
        AiRecommendationType.traffic => Icons.traffic,
        AiRecommendationType.weather => Icons.cloud_outlined,
        AiRecommendationType.fuel => Icons.local_gas_station_outlined,
        AiRecommendationType.battery => Icons.battery_charging_full,
        AiRecommendationType.driving => Icons.directions_car_outlined,
        AiRecommendationType.improvement => Icons.trending_up,
        AiRecommendationType.general => Icons.lightbulb_outline,
      };

  Color color(ThemeData theme) => switch (this) {
        AiRecommendationType.safety ||
        AiRecommendationType.reroute =>
          theme.colorScheme.error,
        AiRecommendationType.traffic ||
        AiRecommendationType.weather =>
          theme.colorScheme.tertiary,
        AiRecommendationType.improvement => theme.colorScheme.secondary,
        _ => theme.colorScheme.primary,
      };
}
