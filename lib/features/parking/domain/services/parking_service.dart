import 'package:rihla/features/parking/domain/entities/parking_location.dart';

abstract class ParkingService {
  Future<List<ParkingLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  });
}
