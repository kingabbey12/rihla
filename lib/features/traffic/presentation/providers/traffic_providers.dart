import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/traffic/data/datasources/traffic_datasource.dart';
import 'package:rihla/features/traffic/data/repositories/traffic_repository_impl.dart';
import 'package:rihla/features/traffic/data/services/live_traffic_service.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/errors/traffic_failure.dart';
import 'package:rihla/features/traffic/domain/models/traffic_state.dart';
import 'package:rihla/features/traffic/domain/repositories/traffic_repository.dart';
import 'package:rihla/features/traffic/domain/services/traffic_service.dart';

final tomtomTrafficDatasourceProvider = Provider<TomTomTrafficDatasource>(
  (ref) => TomTomTrafficDatasource(ref.watch(apiClientProvider)),
);

final heuristicTrafficDatasourceProvider = Provider<HeuristicTrafficDatasource>(
  (ref) => HeuristicTrafficDatasource(),
);

final trafficServiceProvider = Provider<TrafficService>(
  (ref) => LiveTrafficService(
    ref.watch(tomtomTrafficDatasourceProvider),
    ref.watch(heuristicTrafficDatasourceProvider),
  ),
);

final trafficRepositoryProvider = Provider<TrafficRepository>(
  (ref) => TrafficRepositoryImpl(ref.watch(trafficServiceProvider)),
);

final trafficControllerProvider =
    NotifierProvider<TrafficController, TrafficState>(TrafficController.new);

class TrafficController extends Notifier<TrafficState> {
  @override
  TrafficState build() => const TrafficIdle();

  Future<void> fetchAlongRoute({
    required List<({double latitude, double longitude})> coordinates,
    required double freeFlowDurationMinutes,
  }) async {
    state = const TrafficLoading();
    try {
      final snapshot =
          await ref.read(trafficRepositoryProvider).getTrafficAlongRoute(
                coordinates: coordinates,
                freeFlowDurationMinutes: freeFlowDurationMinutes,
              );
      state = TrafficReady(snapshot);
    } on TrafficFailure catch (failure) {
      state = TrafficError(failure);
    } catch (e) {
      state = TrafficError(TrafficServiceFailure(e.toString()));
    }
  }

  /// Fetches a live traffic snapshot for the area around [latitude]/[longitude].
  ///
  /// Used when the Traffic & Incidents screen is opened directly (no active
  /// route): we build a short local corridor centred on the user's position so
  /// the live/heuristic service can return a realistic area estimate instead of
  /// leaving the screen empty.
  Future<void> fetchForArea({
    required double latitude,
    required double longitude,
  }) async {
    // Sample a ~8 km ring around the user (N/E/S/W) so the estimate reflects
    // local road network in all directions, not just one corridor.
    const spanDeg = 0.035;
    const freeFlowDurationMinutes = 16.0;
    await fetchAlongRoute(
      coordinates: [
        (latitude: latitude, longitude: longitude),
        (latitude: latitude + spanDeg, longitude: longitude),
        (latitude: latitude + spanDeg, longitude: longitude + spanDeg),
        (latitude: latitude, longitude: longitude + spanDeg),
        (latitude: latitude - spanDeg, longitude: longitude + spanDeg),
        (latitude: latitude - spanDeg, longitude: longitude),
        (latitude: latitude - spanDeg, longitude: longitude - spanDeg),
        (latitude: latitude, longitude: longitude - spanDeg),
        (latitude: latitude + spanDeg, longitude: longitude - spanDeg),
        (latitude: latitude + spanDeg, longitude: longitude),
      ],
      freeFlowDurationMinutes: freeFlowDurationMinutes,
    );
  }

  void reset() => state = const TrafficIdle();
}

final trafficSnapshotProvider = Provider<TrafficSnapshot?>((ref) {
  final s = ref.watch(trafficControllerProvider);
  return s is TrafficReady ? s.snapshot : null;
});

final trafficDensityProvider = Provider<TrafficDensity?>((ref) {
  return ref.watch(trafficSnapshotProvider)?.density;
});

final trafficDelayMinutesProvider = Provider<int?>((ref) {
  return ref.watch(trafficSnapshotProvider)?.travelDelayMinutes;
});
