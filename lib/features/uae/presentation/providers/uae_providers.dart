import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/uae/data/datasources/uae_local_datasource.dart';
import 'package:rihla/features/uae/data/repositories/uae_repository_impl.dart';
import 'package:rihla/features/uae/data/services/uae_service_impl.dart';
import 'package:rihla/features/uae/data/utils/uae_hazard_mapper.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/models/uae_state.dart';
import 'package:rihla/features/uae/domain/repositories/uae_repository.dart';
import 'package:rihla/features/uae/domain/services/uae_service.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';

final uaeLocalDatasourceProvider = Provider<UaeLocalDatasource>(
  (ref) => UaeLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final uaeRepositoryProvider = Provider<UaeRepository>(
  (ref) => UaeRepositoryImpl(ref.watch(uaeLocalDatasourceProvider)),
);

final uaeServiceProvider = Provider<UaeService>(
  (ref) => UaeServiceImpl(),
);

final uaePreferencesProvider = Provider<UaePreferences>(
  (ref) => ref.watch(uaeRepositoryProvider).getPreferences(),
);

/// Latest UAE intelligence snapshot (refreshed during navigation).
final uaeIntelligenceSnapshotProvider =
    FutureProvider<UaeIntelligenceSnapshot?>((ref) async {
  final session = ref.watch(navigationSessionProvider);
  final position = ref.watch(navigationCurrentPositionProvider);
  final road = ref.watch(navigationCurrentRoadProvider);
  final prefs = ref.watch(uaePreferencesProvider);
  final weather = ref.watch(weatherSnapshotProvider);

  final lat = position?.latitude ?? session?.currentPosition.latitude;
  final lng = position?.longitude ?? session?.currentPosition.longitude;

  final snapshot = await ref.read(uaeServiceProvider).evaluate(
        latitude: lat,
        longitude: lng,
        speedKmh: session?.speedKmh,
        remainingDistanceKm: session?.remainingDistanceKm,
        currentRoad: road ?? session?.currentRoad,
        preferences: prefs,
        weather: weather,
      );

  await ref.read(uaeRepositoryProvider).saveSnapshot(snapshot);
  return snapshot;
});

/// UAE hazards for Safety Engine integration.
final uaeSafetyHazardsProvider = Provider<List<Hazard>>((ref) {
  final snapshot = ref.watch(uaeIntelligenceSnapshotProvider).value;
  if (snapshot == null) return [];
  return uaeAlertsToHazards(snapshot.alerts);
});

final uaeControllerProvider =
    NotifierProvider<UaeController, UaeState>(UaeController.new);

class UaeController extends Notifier<UaeState> {
  @override
  UaeState build() {
    final snapshot = ref.read(uaeRepositoryProvider).getLastSnapshot();
    if (snapshot != null) return UaeReady(snapshot: snapshot);
    return const UaeInitial();
  }

  Future<void> refresh() async {
    final snapshot = await ref.read(uaeIntelligenceSnapshotProvider.future);
    if (snapshot != null) {
      state = UaeReady(snapshot: snapshot);
    }
  }

  Future<void> updatePreferences(UaePreferences preferences) async {
    await ref.read(uaeRepositoryProvider).savePreferences(preferences);
    ref.invalidate(uaePreferencesProvider);
    await refresh();
  }
}
