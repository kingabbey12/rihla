import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:rihla/features/fuel/domain/services/fuel_service.dart';

class FuelRepositoryImpl implements FuelRepository {
  FuelRepositoryImpl(this._service);

  final FuelService _service;

  @override
  Future<List<FuelStation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) =>
      _service.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
