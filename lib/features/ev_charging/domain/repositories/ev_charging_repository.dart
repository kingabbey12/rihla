import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';

abstract class EvChargingRepository {
  Future<List<EvCharger>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  });
}
