import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/ev_charging/data/datasources/open_charge_map_datasource.dart';
import 'package:rihla/features/ev_charging/data/repositories/ev_charging_repository_impl.dart';
import 'package:rihla/features/ev_charging/data/services/open_charge_map_ev_service.dart';
import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/repositories/ev_charging_repository.dart';
import 'package:rihla/features/ev_charging/domain/services/ev_charging_service.dart';

final openChargeMapDatasourceProvider = Provider<OpenChargeMapDatasource>(
  (ref) => OpenChargeMapDatasource(ref.watch(apiClientProvider)),
);

final evChargingServiceProvider = Provider<EvChargingService>(
  (ref) => OpenChargeMapEvService(ref.watch(openChargeMapDatasourceProvider)),
);

final evChargingRepositoryProvider = Provider<EvChargingRepository>(
  (ref) => EvChargingRepositoryImpl(ref.watch(evChargingServiceProvider)),
);

final evChargingControllerProvider =
    NotifierProvider<EvChargingController, AsyncValue<List<EvCharger>>>(
  EvChargingController.new,
);

class EvChargingController extends Notifier<AsyncValue<List<EvCharger>>> {
  @override
  AsyncValue<List<EvCharger>> build() => const AsyncData([]);

  Future<void> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(evChargingRepositoryProvider).findNearby(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
          ),
    );
  }
}
