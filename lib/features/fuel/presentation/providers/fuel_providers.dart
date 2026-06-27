import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/fuel/data/datasources/fuel_datasource.dart';
import 'package:rihla/features/fuel/data/repositories/fuel_repository_impl.dart';
import 'package:rihla/features/fuel/data/services/live_fuel_service.dart';
import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:rihla/features/fuel/domain/services/fuel_service.dart';

final fuelDatasourceProvider = Provider<FuelDatasource>(
  (ref) => FuelDatasource(ref.watch(apiClientProvider)),
);

final fuelServiceProvider = Provider<FuelService>(
  (ref) => LiveFuelService(ref.watch(fuelDatasourceProvider)),
);

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => FuelRepositoryImpl(ref.watch(fuelServiceProvider)),
);

final fuelControllerProvider =
    NotifierProvider<FuelController, AsyncValue<List<FuelStation>>>(
  FuelController.new,
);

class FuelController extends Notifier<AsyncValue<List<FuelStation>>> {
  @override
  AsyncValue<List<FuelStation>> build() => const AsyncData([]);

  Future<void> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fuelRepositoryProvider).findNearby(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
          ),
    );
  }
}
