import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';

/// UAE driving intelligence service.
abstract class UaeService {
  Future<UaeIntelligenceSnapshot> evaluate({
    required double? latitude,
    required double? longitude,
    double? speedKmh,
    double? remainingDistanceKm,
    String? currentRoad,
    UaePreferences? preferences,
    WeatherSnapshot? weather,
  });

  UaeRegion detectRegion(double latitude, double longitude);
}
