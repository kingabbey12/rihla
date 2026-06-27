import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_driving_rule.dart';
import 'package:rihla/features/uae/domain/entities/uae_holiday_traffic.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/uae/domain/entities/uae_toll_gate.dart';
import 'package:rihla/features/uae/domain/entities/uae_weather_alert.dart';

/// Salik toll summary for a journey (informational only).
class UaeSalikSummary {
  const UaeSalikSummary({
    this.upcomingGates = const [],
    this.estimatedTollCount = 0,
    this.estimatedTotalAed = 0,
    this.nextGate,
  });

  final List<UaeTollGate> upcomingGates;
  final int estimatedTollCount;
  final double estimatedTotalAed;
  final UaeTollGate? nextGate;

  Map<String, String> toSummaryMap() => {
        'toll_count': estimatedTollCount.toString(),
        'estimated_aed': estimatedTotalAed.toStringAsFixed(0),
        if (nextGate != null) 'next_gate': nextGate!.name,
      };
}

/// Regional service recommendation.
class UaeRegionalService {
  const UaeRegionalService({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceKm;
}

/// Emergency directory contact.
class UaeEmergencyContact {
  const UaeEmergencyContact({
    required this.id,
    required this.name,
    required this.number,
    required this.category,
    this.region,
  });

  final String id;
  final String name;
  final String number;
  final String category;
  final UaeRegion? region;
}

/// User preferences for UAE intelligence features.
class UaePreferences {
  const UaePreferences({
    this.preferredRegion = UaeRegion.dubai,
    this.useMetricUnits = true,
    this.salikAlertsEnabled = true,
    this.cameraAlertsEnabled = true,
    this.weatherAlertsEnabled = true,
    this.holidayTrafficAlertsEnabled = true,
    this.languageCode = 'en',
  });

  final UaeRegion preferredRegion;
  final bool useMetricUnits;
  final bool salikAlertsEnabled;
  final bool cameraAlertsEnabled;
  final bool weatherAlertsEnabled;
  final bool holidayTrafficAlertsEnabled;
  final String languageCode;

  UaePreferences copyWith({
    UaeRegion? preferredRegion,
    bool? useMetricUnits,
    bool? salikAlertsEnabled,
    bool? cameraAlertsEnabled,
    bool? weatherAlertsEnabled,
    bool? holidayTrafficAlertsEnabled,
    String? languageCode,
  }) {
    return UaePreferences(
      preferredRegion: preferredRegion ?? this.preferredRegion,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      salikAlertsEnabled: salikAlertsEnabled ?? this.salikAlertsEnabled,
      cameraAlertsEnabled: cameraAlertsEnabled ?? this.cameraAlertsEnabled,
      weatherAlertsEnabled: weatherAlertsEnabled ?? this.weatherAlertsEnabled,
      holidayTrafficAlertsEnabled:
          holidayTrafficAlertsEnabled ?? this.holidayTrafficAlertsEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferredRegion': preferredRegion.name,
        'useMetricUnits': useMetricUnits,
        'salikAlertsEnabled': salikAlertsEnabled,
        'cameraAlertsEnabled': cameraAlertsEnabled,
        'weatherAlertsEnabled': weatherAlertsEnabled,
        'holidayTrafficAlertsEnabled': holidayTrafficAlertsEnabled,
        'languageCode': languageCode,
      };

  factory UaePreferences.fromJson(Map<String, dynamic> json) {
    return UaePreferences(
      preferredRegion: UaeRegion.values.firstWhere(
        (r) => r.name == json['preferredRegion'],
        orElse: () => UaeRegion.dubai,
      ),
      useMetricUnits: json['useMetricUnits'] as bool? ?? true,
      salikAlertsEnabled: json['salikAlertsEnabled'] as bool? ?? true,
      cameraAlertsEnabled: json['cameraAlertsEnabled'] as bool? ?? true,
      weatherAlertsEnabled: json['weatherAlertsEnabled'] as bool? ?? true,
      holidayTrafficAlertsEnabled:
          json['holidayTrafficAlertsEnabled'] as bool? ?? true,
      languageCode: json['languageCode'] as String? ?? 'en',
    );
  }

  static const defaults = UaePreferences();
}

/// Aggregated UAE intelligence for navigation and AI.
class UaeIntelligenceSnapshot {
  const UaeIntelligenceSnapshot({
    required this.region,
    this.roadType,
    this.alerts = const [],
    this.drivingRules = const [],
    this.weatherAlerts = const [],
    this.holidayTraffic = const [],
    this.salikSummary = const UaeSalikSummary(),
    this.regionalServices = const [],
    this.emergencyContacts = const [],
    this.evaluatedAt,
  });

  final UaeRegion region;
  final String? roadType;
  final List<UaeAlert> alerts;
  final List<UaeDrivingRule> drivingRules;
  final List<UaeWeatherAlert> weatherAlerts;
  final List<UaeHolidayTraffic> holidayTraffic;
  final UaeSalikSummary salikSummary;
  final List<UaeRegionalService> regionalServices;
  final List<UaeEmergencyContact> emergencyContacts;
  final DateTime? evaluatedAt;

  Map<String, String> toAiSummaryMap() {
    final map = <String, String>{
      'emirate': region.displayName,
      if (roadType != null) 'road_type': roadType!,
      'salik_tolls': salikSummary.estimatedTollCount.toString(),
      'salik_aed': salikSummary.estimatedTotalAed.toStringAsFixed(0),
      if (salikSummary.nextGate != null)
        'next_salik': salikSummary.nextGate!.name,
    };
    if (weatherAlerts.isNotEmpty) {
      map['weather_alert'] = weatherAlerts.first.title;
    }
    if (holidayTraffic.isNotEmpty) {
      map['holiday_traffic'] = holidayTraffic.first.title;
    }
    if (drivingRules.isNotEmpty) {
      map['driving_rule'] = drivingRules.first.title;
    }
    if (alerts.isNotEmpty) {
      map['primary_alert'] = alerts.first.title;
    }
    return map;
  }
}
