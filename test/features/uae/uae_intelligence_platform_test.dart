import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/uae/data/catalog/uae_catalog.dart';
import 'package:rihla/features/uae/data/services/uae_compliance_service_impl.dart';
import 'package:rihla/features/uae/data/services/uae_intelligence_engine.dart';
import 'package:rihla/features/uae/data/services/uae_service_impl.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

void main() {
  final engine = UaeIntelligenceEngine();
  final service = UaeServiceImpl(engine: engine);
  final compliance = UaeComplianceServiceImpl();

  group('Salik calculations', () {
    test('detects gates near Dubai Marina', () {
      final summary = engine.calculateSalikSummary(
        latitude: 25.0805,
        longitude: 55.1403,
        journeyRadiusKm: 30,
      );
      expect(summary.estimatedTollCount, greaterThan(0));
      expect(summary.estimatedTotalAed, greaterThan(0));
    });

    test('next gate within alert radius', () {
      final summary = engine.calculateSalikSummary(
        latitude: 25.2401,
        longitude: 55.3522,
        alertRadiusKm: 1.0,
      );
      expect(summary.nextGate, isNotNull);
      expect(summary.nextGate!.name, contains('Garhoud'));
    });
  });

  group('Camera alerts', () {
    test('generates speed camera alert near Sheikh Zayed Road', () {
      final alerts = engine.cameraAlerts(
        latitude: 25.2048,
        longitude: 55.2708,
        alertRadiusKm: 2,
      );
      expect(alerts, isNotEmpty);
      expect(alerts.first.type, UaeAlertType.speedCamera);
      expect(alerts.first.message, contains('Speed limit'));
    });

    test('disabled when camera alerts off', () async {
      final snapshot = await service.evaluate(
        latitude: 25.2048,
        longitude: 55.2708,
        preferences: const UaePreferences(cameraAlertsEnabled: false),
      );
      expect(
        snapshot.alerts.where((a) => a.type == UaeAlertType.speedCamera),
        isEmpty,
      );
    });
  });

  group('Weather alerts', () {
    test('detects fog from weather snapshot', () {
      final alerts = engine.weatherAlerts(
        WeatherSnapshot(
          current: WeatherConditions(
            latitude: 25.2,
            longitude: 55.27,
            temperatureCelsius: 22,
            summary: 'Dense fog',
            rainProbabilityPercent: 10,
            visibilityMeters: 500,
            windSpeedKmh: 10,
            uvIndex: 2,
            observedAt: DateTime(2026),
          ),
          forecast: const [],
        ),
      );
      expect(alerts.any((a) => a.title.contains('Fog')), isTrue);
    });

    test('detects extreme heat', () {
      final alerts = engine.weatherAlerts(
        WeatherSnapshot(
          current: WeatherConditions(
            latitude: 25.2,
            longitude: 55.27,
            temperatureCelsius: 48,
            summary: 'Clear sky',
            rainProbabilityPercent: 0,
            visibilityMeters: 10000,
            windSpeedKmh: 15,
            uvIndex: 11,
            observedAt: DateTime(2026),
          ),
          forecast: const [],
        ),
      );
      expect(alerts.any((a) => a.title.contains('heat')), isTrue);
    });
  });

  group('Holiday traffic', () {
    test('includes airport traffic prediction', () {
      final holidays = UaeCatalog.activeHolidayTraffic(DateTime(2026, 6, 1));
      expect(holidays.any((h) => h.type.name == 'airport'), isTrue);
    });

    test('national day in December', () {
      final holidays = UaeCatalog.activeHolidayTraffic(DateTime(2026, 12, 2));
      expect(holidays.any((h) => h.type.name == 'nationalDay'), isTrue);
    });
  });

  group('Regional recommendations', () {
    test('returns nearest fuel and hospital services', () {
      final services = engine.nearbyServices(25.2048, 55.2708, limit: 3);
      expect(services.length, 3);
      expect(services.first.distanceKm, lessThan(services.last.distanceKm));
    });
  });

  group('AI UAE context', () {
    test('snapshot provides AI summary map', () async {
      final snapshot = await service.evaluate(
        latitude: 25.2048,
        longitude: 55.2708,
        currentRoad: 'Sheikh Zayed Road',
      );
      final map = snapshot.toAiSummaryMap();
      expect(map['emirate'], isNotNull);
      expect(map.containsKey('salik_tolls'), isTrue);
    });

    test('detects Dubai region', () {
      expect(
        engine.detectRegion(25.2, 55.27),
        UaeRegion.dubai,
      );
    });
  });

  group('Compliance rules', () {
    test('blocks payment encouragement messages', () {
      expect(
        compliance.validateAlertMessage('Please pay now at the toll'),
        isFalse,
      );
    });

    test('blocks speed encouragement', () {
      expect(
        compliance.validateAlertMessage('Speed up to beat the camera'),
        isFalse,
      );
    });

    test('allows advisory camera message', () {
      expect(
        compliance.validateAlertMessage(
          'Speed limit 100 km/h. Maintain legal speed.',
        ),
        isTrue,
      );
    });

    test('filters non-compliant alerts', () {
      final filtered = compliance.filterAlerts([
        const UaeAlert(
          id: 'bad',
          type: UaeAlertType.salik,
          title: 'Bad',
          message: 'auto-pay now',
          distanceAheadKm: 1,
        ),
        const UaeAlert(
          id: 'good',
          type: UaeAlertType.salik,
          title: 'Salik ahead',
          message: 'Ensure Salik tag is active.',
          distanceAheadKm: 1,
        ),
      ]);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'good');
    });
  });

  group('Emergency directory', () {
    test('includes police ambulance fire', () {
      final contacts = UaeCatalog.emergencyDirectory(UaeRegion.dubai);
      expect(contacts.any((c) => c.category == 'police'), isTrue);
      expect(contacts.any((c) => c.category == 'ambulance'), isTrue);
      expect(contacts.any((c) => c.category == 'fire'), isTrue);
    });
  });
}
