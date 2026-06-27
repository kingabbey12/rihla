import 'package:rihla/features/fuel/data/datasources/fuel_datasource.dart';
import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/services/fuel_service.dart';

class LiveFuelService implements FuelService {
  LiveFuelService(this._datasource);

  final FuelDatasource _datasource;

  @override
  Future<List<FuelStation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) =>
      _datasource.fetchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
