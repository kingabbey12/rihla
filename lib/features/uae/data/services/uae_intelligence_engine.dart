import 'package:rihla/features/uae/data/catalog/uae_catalog.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';
import 'package:rihla/features/uae/domain/entities/uae_driving_rule.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/uae/domain/entities/uae_speed_camera.dart';
import 'package:rihla/features/uae/domain/entities/uae_toll_gate.dart';
import 'package:rihla/features/uae/domain/entities/uae_weather_alert.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// Core UAE intelligence calculations.
class UaeIntelligenceEngine {
  UaeRegion detectRegion(double latitude, double longitude) {
    if (latitude > 25.0 && longitude > 55.0) return UaeRegion.dubai;
    if (latitude > 24.3 && latitude < 25.0) return UaeRegion.sharjah;
    if (latitude < 24.5) return UaeRegion.abuDhabi;
    if (longitude > 56.0) return UaeRegion.fujairah;
    if (latitude > 25.5) return UaeRegion.rasAlKhaimah;
    return UaeRegion.dubai;
  }

  UaeSalikSummary calculateSalikSummary({
    required double latitude,
    required double longitude,
    double alertRadiusKm = 3.0,
    double journeyRadiusKm = 15.0,
  }) {
    final upcoming = <UaeTollGate>[];
    UaeTollGate? nearest;
    var nearestDist = double.infinity;

    for (final gate in UaeCatalog.salikGates) {
      final dist = UaeCatalog.haversineKm(
        latitude,
        longitude,
        gate.latitude,
        gate.longitude,
      );
      if (dist <= journeyRadiusKm) upcoming.add(gate);
      if (dist < nearestDist && dist <= alertRadiusKm) {
        nearestDist = dist;
        nearest = gate;
      }
    }

    upcoming.sort(
      (a, b) => UaeCatalog.haversineKm(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          ).compareTo(
            UaeCatalog.haversineKm(
              latitude,
              longitude,
              b.latitude,
              b.longitude,
            ),
          ),
    );

    final totalAed = upcoming.fold<double>(
      0,
      (sum, g) => sum + g.estimatedFeeAed,
    );

    return UaeSalikSummary(
      upcomingGates: upcoming,
      estimatedTollCount: upcoming.length,
      estimatedTotalAed: totalAed,
      nextGate: nearest,
    );
  }

  List<UaeAlert> cameraAlerts({
    required double latitude,
    required double longitude,
    double alertRadiusKm = 2.0,
    bool enabled = true,
  }) {
    if (!enabled) return [];
    final alerts = <UaeAlert>[];
    for (final camera in UaeCatalog.speedCameras) {
      final dist = UaeCatalog.haversineKm(
        latitude,
        longitude,
        camera.latitude,
        camera.longitude,
      );
      if (dist <= alertRadiusKm) {
        alerts.add(_cameraAlert(camera, dist));
      }
    }
    return alerts..sort((a, b) => a.distanceAheadKm.compareTo(b.distanceAheadKm));
  }

  List<UaeAlert> salikAlerts({
    required UaeSalikSummary summary,
    required double latitude,
    required double longitude,
    bool enabled = true,
  }) {
    if (!enabled || summary.nextGate == null) return [];
    final gate = summary.nextGate!;
    final dist = UaeCatalog.haversineKm(
      latitude,
      longitude,
      gate.latitude,
      gate.longitude,
    );
    return [
      UaeAlert(
        id: 'salik_${gate.id}',
        type: UaeAlertType.salik,
        title: 'Salik ahead: ${gate.name}',
        message:
            'Toll gate in ${dist.toStringAsFixed(1)} km. Estimated fee AED ${gate.estimatedFeeAed.toStringAsFixed(0)}. Ensure Salik tag is active.',
        distanceAheadKm: dist,
        priority: 2,
      ),
    ];
  }

  List<UaeWeatherAlert> weatherAlerts(WeatherSnapshot? weather) {
    if (weather == null) return [];
    final current = weather.current;
    final summary = current.summary.toLowerCase();
    final alerts = <UaeWeatherAlert>[];

    if (summary.contains('fog')) {
      alerts.add(
        const UaeWeatherAlert(
          type: UaeWeatherAlertType.fog,
          title: 'Fog advisory',
          guidance:
              'Reduce speed, use low beams, increase following distance.',
          severity: 4,
        ),
      );
    }
    if (summary.contains('sand') || current.windSpeedKmh > 45) {
      alerts.add(
        const UaeWeatherAlert(
          type: UaeWeatherAlertType.sandstorm,
          title: 'Sandstorm risk',
          guidance: 'Consider delaying travel. Pull over if visibility drops.',
          severity: 5,
        ),
      );
    }
    if (current.rainProbabilityPercent > 60 || summary.contains('rain')) {
      alerts.add(
        const UaeWeatherAlert(
          type: UaeWeatherAlertType.heavyRain,
          title: 'Heavy rain advisory',
          guidance:
              'Roads may be slippery. Reduce speed and avoid flooded areas.',
          severity: 3,
        ),
      );
    }
    if (current.temperatureCelsius > 45) {
      alerts.add(
        const UaeWeatherAlert(
          type: UaeWeatherAlertType.extremeHeat,
          title: 'Extreme heat',
          guidance:
              'Check tire pressure and coolant. Stay hydrated on long drives.',
          severity: 2,
        ),
      );
    }
    if (summary.contains('flood')) {
      alerts.add(
        const UaeWeatherAlert(
          type: UaeWeatherAlertType.floodProne,
          title: 'Flood-prone area',
          guidance: 'Do not drive through standing water.',
          severity: 5,
        ),
      );
    }
    return alerts;
  }

  List<UaeRegionalService> nearbyServices(
    double latitude,
    double longitude, {
    int limit = 5,
  }) {
    final withDistance = UaeCatalog.regionalServices.map((s) {
      final dist = UaeCatalog.haversineKm(
        latitude,
        longitude,
        s.latitude,
        s.longitude,
      );
      return UaeRegionalService(
        id: s.id,
        name: s.name,
        category: s.category,
        latitude: s.latitude,
        longitude: s.longitude,
        distanceKm: dist,
      );
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withDistance.take(limit).toList();
  }

  List<UaeDrivingRule> applicableRules({
    required List<UaeWeatherAlert> weatherAlerts,
    String? roadType,
    double? speedKmh,
  }) {
    final conditions = <String>{};
    for (final w in weatherAlerts) {
      conditions.add(switch (w.type) {
        UaeWeatherAlertType.fog => 'fog',
        UaeWeatherAlertType.heavyRain => 'rain',
        UaeWeatherAlertType.sandstorm => 'sandstorm',
        _ => w.type.name,
      });
    }
    if (roadType?.toLowerCase().contains('desert') == true) {
      conditions.add('desert_road');
    }
    if (speedKmh != null && speedKmh < 50) conditions.add('school_zone');

    return UaeCatalog.drivingRules.where((rule) {
      if (rule.conditions.isEmpty) return true;
      return rule.conditions.any(conditions.contains);
    }).toList();
  }

  String? inferRoadType(String? currentRoad) {
    if (currentRoad == null) return null;
    final lower = currentRoad.toLowerCase();
    if (lower.contains('sheikh') || lower.contains('e11')) return 'highway';
    if (lower.contains('desert')) return 'desert_road';
    if (lower.contains('school')) return 'school_zone';
    return 'urban';
  }

  UaeAlert _cameraAlert(UaeSpeedCamera camera, double distKm) {
    final typeLabel = switch (camera.type) {
      UaeCameraType.fixed => 'Speed camera',
      UaeCameraType.averageSpeed => 'Average speed zone',
      UaeCameraType.redLight => 'Red light camera',
      UaeCameraType.schoolZone => 'School zone camera',
    };
    return UaeAlert(
      id: 'cam_${camera.id}',
      type: UaeAlertType.speedCamera,
      title: '$typeLabel: ${camera.name}',
      message:
          'Speed limit ${camera.speedLimitKmh} km/h. Maintain legal speed.',
      distanceAheadKm: distKm,
      priority: 3,
    );
  }
}
