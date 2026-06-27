import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';

abstract class FuelService {
  Future<List<FuelStation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });
}
