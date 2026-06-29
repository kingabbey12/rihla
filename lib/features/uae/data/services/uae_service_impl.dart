import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:rihla/features/uae/data/catalog/uae_catalog.dart';
import 'package:rihla/features/uae/data/services/uae_compliance_service_impl.dart';
import 'package:rihla/features/uae/data/services/uae_intelligence_engine.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';
import 'package:rihla/features/uae/domain/entities/uae_holiday_traffic.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/uae/domain/entities/uae_weather_alert.dart';
import 'package:rihla/features/uae/domain/services/uae_compliance_service.dart';
import 'package:rihla/features/uae/domain/services/uae_service.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

class UaeServiceImpl implements UaeService {
  UaeServiceImpl({
    UaeIntelligenceEngine? engine,
    UaeComplianceService? compliance,
    FuelRepository? fuelRepository,
  })  : _engine = engine ?? UaeIntelligenceEngine(),
        _compliance = compliance ?? UaeComplianceServiceImpl(),
        _fuelRepository = fuelRepository;

  final UaeIntelligenceEngine _engine;
  final UaeComplianceService _compliance;
  final FuelRepository? _fuelRepository;

  @override
  UaeRegion detectRegion(double latitude, double longitude) =>
      _engine.detectRegion(latitude, longitude);

  @override
  Future<UaeIntelligenceSnapshot> evaluate({
    required double? latitude,
    required double? longitude,
    double? speedKmh,
    double? remainingDistanceKm,
    String? currentRoad,
    UaePreferences? preferences,
    WeatherSnapshot? weather,
  }) async {
    final prefs = preferences ?? UaePreferences.defaults;
    if (latitude == null || longitude == null) {
      return UaeIntelligenceSnapshot(
        region: prefs.preferredRegion,
        evaluatedAt: DateTime.now(),
        emergencyContacts: UaeCatalog.emergencyDirectory(prefs.preferredRegion),
      );
    }

    final region = _engine.detectRegion(latitude, longitude);
    final roadType = _engine.inferRoadType(currentRoad);
    final weatherAlerts = prefs.weatherAlertsEnabled
        ? _engine.weatherAlerts(weather)
        : <UaeWeatherAlert>[];
    final holidayTraffic = prefs.holidayTrafficAlertsEnabled
        ? UaeCatalog.activeHolidayTraffic(DateTime.now())
        : <UaeHolidayTraffic>[];

    final salikSummary = _engine.calculateSalikSummary(
      latitude: latitude,
      longitude: longitude,
    );

    final alerts = <UaeAlert>[
      if (prefs.salikAlertsEnabled)
        ..._engine.salikAlerts(
          summary: salikSummary,
          latitude: latitude,
          longitude: longitude,
        ),
      if (prefs.cameraAlertsEnabled)
        ..._engine.cameraAlerts(
          latitude: latitude,
          longitude: longitude,
        ),
      ...weatherAlerts.map(
        (w) => UaeAlert(
          id: 'weather_${w.type.name}',
          type: UaeAlertType.weather,
          title: w.title,
          message: w.guidance,
          distanceAheadKm: 0,
          priority: w.severity,
        ),
      ),
      ...holidayTraffic.map(
        (h) => UaeAlert(
          id: 'holiday_${h.type.name}',
          type: UaeAlertType.holidayTraffic,
          title: h.title,
          message: h.description,
          distanceAheadKm: 0,
          priority: 1,
        ),
      ),
    ];

    final drivingRules = _engine.applicableRules(
      weatherAlerts: weatherAlerts,
      roadType: roadType,
      speedKmh: speedKmh,
    );

  for (final rule in drivingRules.take(2)) {
      alerts.add(
        UaeAlert(
          id: 'rule_${rule.id}',
          type: UaeAlertType.drivingRule,
          title: rule.title,
          message: rule.description,
          distanceAheadKm: 0,
          priority: 1,
        ),
      );
    }

    final snapshot = UaeIntelligenceSnapshot(
      region: region,
      roadType: roadType,
      alerts: alerts,
      drivingRules: drivingRules,
      weatherAlerts: weatherAlerts,
      holidayTraffic: holidayTraffic,
      salikSummary: salikSummary,
      regionalServices: await _regionalServices(latitude, longitude),
      emergencyContacts: UaeCatalog.emergencyDirectory(region),
      evaluatedAt: DateTime.now(),
    );

    return _compliance.sanitizeSnapshot(snapshot);
  }

  /// Static catalog services merged with live ADNOC/ENOC/Emarat/EPPCO stations.
  Future<List<UaeRegionalService>> _regionalServices(
    double latitude,
    double longitude,
  ) async {
    final static = _engine.nearbyServices(latitude, longitude);
    final fuelRepo = _fuelRepository;
    if (fuelRepo == null) return static;

    try {
      final liveFuel = await fuelRepo.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 15,
      );
      final liveServices = liveFuel.map(_fuelToRegional).toList();
      final merged = <UaeRegionalService>[...liveServices];
      for (final s in static) {
        final dup = merged.any(
          (m) =>
              m.name.toLowerCase() == s.name.toLowerCase() ||
              (m.latitude - s.latitude).abs() < 0.001 &&
                  (m.longitude - s.longitude).abs() < 0.001,
        );
        if (!dup) merged.add(s);
      }
      merged.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return merged.take(8).toList();
    } catch (_) {
      return static;
    }
  }

  UaeRegionalService _fuelToRegional(FuelStation station) {
    final brand = station.name.toLowerCase();
    final category = brand.contains('adnoc')
        ? 'fuel_adnoc'
        : brand.contains('enoc')
            ? 'fuel_enoc'
            : brand.contains('emarat')
                ? 'fuel_emarat'
                : brand.contains('eppco')
                    ? 'fuel_eppco'
                    : 'fuel';
    return UaeRegionalService(
      id: station.id,
      name: station.name,
      category: category,
      latitude: station.latitude,
      longitude: station.longitude,
      distanceKm: station.distanceKm,
    );
  }
}
