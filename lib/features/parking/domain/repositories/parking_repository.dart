import 'package:rihla/features/parking/domain/entities/parking_location.dart';

abstract class ParkingRepository {
  Future<List<ParkingLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  });
}
