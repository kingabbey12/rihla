import 'package:rihla/features/ev_charging/data/datasources/open_charge_map_datasource.dart';
import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/services/ev_charging_service.dart';

class OpenChargeMapEvService implements EvChargingService {
  OpenChargeMapEvService(this._datasource);

  final OpenChargeMapDatasource _datasource;

  @override
  Future<List<EvCharger>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) =>
      _datasource.fetchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}
