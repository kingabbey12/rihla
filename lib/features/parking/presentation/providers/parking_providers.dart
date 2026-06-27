import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/parking/data/datasources/parking_datasource.dart';
import 'package:rihla/features/parking/data/repositories/parking_repository_impl.dart';
import 'package:rihla/features/parking/data/services/live_parking_service.dart';
import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/errors/parking_failure.dart';
import 'package:rihla/features/parking/domain/repositories/parking_repository.dart';
import 'package:rihla/features/parking/domain/services/parking_service.dart';

final parkingDatasourceProvider = Provider<ParkingDatasource>(
  (ref) => ParkingDatasource(ref.watch(apiClientProvider)),
);

final parkingServiceProvider = Provider<ParkingService>(
  (ref) => LiveParkingService(ref.watch(parkingDatasourceProvider)),
);

final parkingRepositoryProvider = Provider<ParkingRepository>(
  (ref) => ParkingRepositoryImpl(ref.watch(parkingServiceProvider)),
);

sealed class ParkingState {
  const ParkingState();
}

final class ParkingIdle extends ParkingState {
  const ParkingIdle();
}

final class ParkingLoading extends ParkingState {
  const ParkingLoading();
}

final class ParkingReady extends ParkingState {
  const ParkingReady(this.locations);
  final List<ParkingLocation> locations;
}

final class ParkingError extends ParkingState {
  const ParkingError(this.failure);
  final ParkingFailure failure;
}

final parkingControllerProvider =
    NotifierProvider<ParkingController, ParkingState>(ParkingController.new);

class ParkingController extends Notifier<ParkingState> {
  @override
  ParkingState build() => const ParkingIdle();

  Future<void> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  }) async {
    state = const ParkingLoading();
    try {
      final locations = await ref.read(parkingRepositoryProvider).findNearby(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
          );
      state = ParkingReady(locations);
    } on ParkingFailure catch (failure) {
      state = ParkingError(failure);
    } catch (e) {
      state = ParkingError(ParkingServiceFailure(e.toString()));
    }
  }

  void reset() => state = const ParkingIdle();
}
