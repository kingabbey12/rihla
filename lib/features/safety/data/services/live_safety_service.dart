import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/safety/data/datasources/overpass_hazard_datasource.dart';
import 'package:rihla/features/safety/data/services/weighted_safety_engine.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';
import 'package:rihla/features/safety/domain/services/safety_engine.dart';
import 'package:rihla/features/safety/domain/services/safety_service.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// Production safety evaluation combining live hazards, weather, and traffic.
class LiveSafetyService implements SafetyService {
  LiveSafetyService({
    required OverpassHazardDatasource hazardDatasource,
    SafetyEngine? engine,
  })  : _hazards = hazardDatasource,
        _engine = engine ?? WeightedSafetyEngine();

  final OverpassHazardDatasource _hazards;
  final SafetyEngine _engine;

  WeatherSnapshot? _lastWeather;
  TrafficSnapshot? _lastTraffic;
  List<Hazard> _uaeHazards = [];

  void updateWeather(WeatherSnapshot? weather) => _lastWeather = weather;
  void updateTraffic(TrafficSnapshot? traffic) => _lastTraffic = traffic;
  void updateUaeHazards(List<Hazard> hazards) => _uaeHazards = hazards;

  @override
  Future<SafetySnapshot> evaluate(
    NavigationSession session, {
    int tickCount = 0,
  }) async {
    final progress = session.routeProgressPercent / 100;
    final speedFactor = (session.speedKmh / 120).clamp(0.0, 1.0);
    final offRoutePenalty = session.isOffRoute ? 15.0 : 0.0;

    final weatherRisk = _weatherRisk();
    final trafficRisk = _trafficRisk(tickCount, speedFactor);

    final roadSafety =
        (85 - tickCount * 1.5 - offRoutePenalty).clamp(40.0, 95.0);
    final driverAlertness =
        (88 - speedFactor * 15 - tickCount * 0.5).clamp(50.0, 95.0);
    final vehicleReadiness = (90 - progress * 5).clamp(60.0, 95.0);
    final journeyRisk =
        (trafficRisk * 0.4 + weatherRisk * 0.3 + offRoutePenalty).clamp(
      10.0,
      95.0,
    );

    final assessment = _engine.compute(
      roadSafety: roadSafety,
      trafficRisk: trafficRisk,
      weatherRisk: weatherRisk,
      driverAlertness: driverAlertness,
      vehicleReadiness: vehicleReadiness,
      journeyRisk: journeyRisk,
      timestamp: DateTime.now(),
    );

    final bbox = _bboxAround(session);
    final osmHazards = await _hazards.fetchNearRoute(
      minLat: bbox.$1,
      minLon: bbox.$2,
      maxLat: bbox.$3,
      maxLon: bbox.$4,
    );

    final hazards = <Hazard>[
      ...osmHazards,
      ..._weatherHazards(session, tickCount),
      ..._sessionHazards(session, tickCount),
      ..._uaeHazards,
    ]..sort((a, b) => a.distanceAheadKm.compareTo(b.distanceAheadKm));

    return SafetySnapshot(
      assessment: assessment,
      hazards: hazards,
      primaryAlert: _primaryAlert(hazards),
    );
  }

  double _weatherRisk() {
    final w = _lastWeather?.current;
    if (w == null) return 20;
    var risk = 10.0;
    if (w.rainProbabilityPercent > 60) risk += 25;
    if (w.visibilityMeters < 2000) risk += 20;
    if (w.windSpeedKmh > 40) risk += 15;
    if (w.uvIndex > 8) risk += 5;
    if (w.summary.toLowerCase().contains('fog')) risk += 30;
  if (w.summary.toLowerCase().contains('thunder')) risk += 35;
    return risk.clamp(10, 95);
  }

  double _trafficRisk(int tickCount, double speedFactor) {
    final t = _lastTraffic;
    if (t == null) {
      return (20 + tickCount * 2.5 + speedFactor * 20).clamp(10.0, 90.0);
    }
    return switch (t.density) {
      TrafficDensity.freeFlow => 15.0,
      TrafficDensity.light => 30.0,
      TrafficDensity.moderate => 50.0,
      TrafficDensity.heavy => 70.0,
      TrafficDensity.standstill => 85.0,
    };
  }

  (double, double, double, double) _bboxAround(NavigationSession session) {
    final lat = session.currentPosition.latitude;
    final lon = session.currentPosition.longitude;
    const delta = 0.05;
    return (lat - delta, lon - delta, lat + delta, lon + delta);
  }

  List<Hazard> _weatherHazards(NavigationSession session, int tickCount) {
    final w = _lastWeather?.current;
    if (w == null) return const [];

    final now = DateTime.now();
    final remaining = session.remainingDistanceKm;
    final hazards = <Hazard>[];

    if (w.summary.toLowerCase().contains('fog') || w.visibilityMeters < 1500) {
      hazards.add(Hazard(
        id: 'wx_fog_$tickCount',
        type: HazardType.custom,
        severity: HazardSeverity.high,
        title: 'Fog advisory',
        description: 'Visibility reduced to ${w.visibilityMeters.round()} m',
        distanceAheadKm: (remaining * 0.2).clamp(0.1, remaining),
        reportedAt: now,
        customLabel: 'Fog',
      ));
    }
    if (w.rainProbabilityPercent > 70) {
      hazards.add(Hazard(
        id: 'wx_rain_$tickCount',
        type: HazardType.heavyRain,
        severity: HazardSeverity.moderate,
        title: 'Heavy rain expected',
        description: '${w.rainProbabilityPercent.round()}% precipitation chance',
        distanceAheadKm: (remaining * 0.15).clamp(0.1, remaining),
        reportedAt: now,
      ));
    }
    if (w.windSpeedKmh > 50) {
      hazards.add(Hazard(
        id: 'wx_wind_$tickCount',
        type: HazardType.sandstorm,
        severity: HazardSeverity.high,
        title: 'High winds',
        description: 'Wind speed ${w.windSpeedKmh.round()} km/h',
        distanceAheadKm: (remaining * 0.3).clamp(0.2, remaining),
        reportedAt: now,
      ));
    }
    if (w.rainProbabilityPercent > 85 && w.summary.contains('Rain')) {
      hazards.add(Hazard(
        id: 'wx_flood_$tickCount',
        type: HazardType.flood,
        severity: HazardSeverity.critical,
        title: 'Flood risk',
        description: 'Heavy rainfall may cause localized flooding',
        distanceAheadKm: (remaining * 0.1).clamp(0.05, remaining),
        reportedAt: now,
      ));
    }
    return hazards;
  }

  List<Hazard> _sessionHazards(NavigationSession session, int tickCount) {
    final now = DateTime.now();
    final remaining = session.remainingDistanceKm;
    final hazards = <Hazard>[];

    if (session.isOffRoute) {
      hazards.add(Hazard(
        id: 'hz_offroute',
        type: HazardType.custom,
        severity: HazardSeverity.critical,
        title: 'Off route',
        description: 'You have left the planned corridor',
        distanceAheadKm: 0,
        reportedAt: now,
        customLabel: 'Route deviation',
      ));
    }

    if (_lastTraffic != null && _lastTraffic!.incidents.isNotEmpty) {
      for (final incident in _lastTraffic!.incidents) {
        hazards.add(Hazard(
          id: 'tr_${incident.id}',
          type: HazardType.accident,
          severity: HazardSeverity.high,
          title: incident.type,
          description: incident.description,
          distanceAheadKm: (remaining * 0.2).clamp(0.1, remaining),
          reportedAt: incident.reportedAt,
        ));
      }
    }

    return hazards;
  }

  Hazard? _primaryAlert(List<Hazard> hazards) {
    if (hazards.isEmpty) return null;
    final active = hazards.where((h) => h.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final sev = b.severity.index.compareTo(a.severity.index);
      if (sev != 0) return sev;
      return a.distanceAheadKm.compareTo(b.distanceAheadKm);
    });
    return active.first;
  }
}
