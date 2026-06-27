import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/repositories/parking_repository.dart';
import 'package:rihla/features/parking/domain/services/parking_service.dart';

class ParkingRepositoryImpl implements ParkingRepository {
  ParkingRepositoryImpl(this._service);

  final ParkingService _service;

  @override
  Future<List<ParkingLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  }) =>
      _service.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
