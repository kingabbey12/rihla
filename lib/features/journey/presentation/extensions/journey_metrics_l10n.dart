import 'package:flutter/material.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

/// Localized labels for journey metric enums.
extension JourneyMetricsL10n on BuildContext {
  String trafficLabel(TrafficLevel level) {
    final l10n = AppLocalizations.of(this);
    return switch (level) {
      TrafficLevel.light => l10n.journeyTrafficLight,
      TrafficLevel.moderate => l10n.journeyTrafficModerate,
      TrafficLevel.heavy => l10n.journeyTrafficHeavy,
    };
  }

  String roadConditionLabel(RoadConditionLevel level) {
    final l10n = AppLocalizations.of(this);
    return switch (level) {
      RoadConditionLevel.excellent => l10n.journeyRoadExcellent,
      RoadConditionLevel.good => l10n.journeyRoadGood,
      RoadConditionLevel.fair => l10n.journeyRoadFair,
      RoadConditionLevel.poor => l10n.journeyRoadPoor,
    };
  }
}
