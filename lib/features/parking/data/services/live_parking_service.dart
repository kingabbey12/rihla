import 'package:rihla/features/parking/data/datasources/parking_datasource.dart';
import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/services/parking_service.dart';

class LiveParkingService implements ParkingService {
  LiveParkingService(this._datasource);

  final ParkingDatasource _datasource;

  @override
  Future<List<ParkingLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  }) =>
      _datasource.fetchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
