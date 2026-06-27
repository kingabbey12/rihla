import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/repositories/ev_charging_repository.dart';
import 'package:rihla/features/ev_charging/domain/services/ev_charging_service.dart';

class EvChargingRepositoryImpl implements EvChargingRepository {
  EvChargingRepositoryImpl(this._service);

  final EvChargingService _service;

  @override
  Future<List<EvCharger>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) =>
      _service.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
