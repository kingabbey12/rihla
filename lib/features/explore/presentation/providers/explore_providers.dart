import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/product_analytics.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/ev_charging/presentation/providers/ev_charging_providers.dart';
import 'package:rihla/features/explore/data/datasources/overpass_poi_datasource.dart';
import 'package:rihla/features/explore/data/datasources/explore_favorites_local_datasource.dart';
import 'package:rihla/features/explore/data/repositories/explore_favorites_repository_impl.dart';
import 'package:rihla/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:rihla/features/explore/data/services/explore_service_impl.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_filter.dart';
import 'package:rihla/features/explore/domain/entities/explore_marker.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/domain/repositories/explore_favorites_repository.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/explore/domain/services/explore_service.dart';
import 'package:rihla/features/fuel/presentation/providers/fuel_providers.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/parking/presentation/providers/parking_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

// —— Infrastructure ————————————————————————————————————————————————————————

final exploreFavoritesLocalDatasourceProvider =
    Provider<ExploreFavoritesLocalDatasource>(
      (ref) =>
          ExploreFavoritesLocalDatasource(ref.watch(sharedPreferencesProvider)),
    );

final exploreFavoritesRepositoryProvider = Provider<ExploreFavoritesRepository>(
  (ref) => ExploreFavoritesRepositoryImpl(
    ref.watch(exploreFavoritesLocalDatasourceProvider),
  ),
);

final overpassPoiDatasourceProvider = Provider<OverpassPoiDatasource>(
  (ref) => OverpassPoiDatasource(ref.watch(apiClientProvider)),
);

final exploreServiceProvider = Provider<ExploreService>(
  (ref) => ExploreServiceImpl(
    offlineRepository: ref.watch(offlineRepositoryProvider),
    fuelRepository: ref.watch(fuelRepositoryProvider),
    evChargingRepository: ref.watch(evChargingRepositoryProvider),
    parkingRepository: ref.watch(parkingRepositoryProvider),
    poiDatasource: ref.watch(overpassPoiDatasourceProvider),
    isOffline: () => ref.read(isOfflineModeProvider),
  ),
);

final exploreRepositoryProvider = Provider<ExploreRepository>(
  (ref) => ExploreRepositoryImpl(ref.watch(exploreServiceProvider)),
);

// —— Explore activation —————————————————————————————————————————————————————

final exploreActiveProvider = NotifierProvider<ExploreActiveNotifier, bool>(
  ExploreActiveNotifier.new,
);

class ExploreActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void activate() => state = true;
  void deactivate() => state = false;
}

// —— Controller ———————————————————————————————————————————————————————————————

final exploreControllerProvider =
    NotifierProvider<ExploreController, ExploreState>(ExploreController.new);

class ExploreController extends Notifier<ExploreState> {
  ExploreCategory? _category;
  ExploreFilter _filter = ExploreFilter.defaults;
  int _page = 0;

  @override
  ExploreState build() => const ExploreIdle();

  Future<void> activate({ExploreCategory? initialCategory}) async {
    ref.read(exploreActiveProvider.notifier).activate();
    if (initialCategory != null) {
      await selectCategory(initialCategory);
    } else {
      await refresh();
    }
  }

  /// Ensures we have a real device position before searching. Without this the
  /// search falls back to the map camera, which is the (0, 0) sentinel until the
  /// map itself resolves GPS — yielding "nearby" results in the Atlantic Ocean.
  Future<void> _ensureLocation() async {
    final location = ref.read(locationControllerProvider);
    if (location is LocationActive) return;
    try {
      await ref.read(locationControllerProvider.notifier).fetchCurrentPosition();
    } catch (_) {
      // Permission denied / GPS off — fall back to the map camera origin.
    }
  }

  /// Best available search origin: the live GPS fix first, then the last known
  /// fix, then the map camera (only once it has resolved to a real location).
  ({double latitude, double longitude}) _resolveOrigin() {
    final location = ref.read(locationControllerProvider);
    final position = switch (location) {
      LocationActive(:final position) => position,
      LocationError(:final lastKnownPosition) => lastKnownPosition,
      _ => null,
    };
    if (position != null) {
      return (latitude: position.latitude, longitude: position.longitude);
    }
    final camera = ref.read(mapCameraProvider);
    return (latitude: camera.latitude, longitude: camera.longitude);
  }

  void deactivate() {
    ref.read(exploreActiveProvider.notifier).deactivate();
    state = const ExploreIdle();
    _category = null;
    _filter = ExploreFilter.defaults;
    _page = 0;
  }

  /// Returns to the discovery landing (no category selected).
  Future<void> showDiscovery() async {
    _category = null;
    _filter = ExploreFilter.defaults;
    _page = 0;
    state = const ExploreLoading();
    await _load();
  }

  Future<void> selectCategory(ExploreCategory category) async {
    trackProductEvent(
      ref,
      AnalyticsEvent.exploreUsed,
      properties: {'category': category.name},
    );
    _category = category;
    _page = 0;
    _filter = _filter.copyWith(category: category);
    state = ExploreLoading(category: category);
    await _load();
  }

  Future<void> applyFilter(ExploreFilter filter) async {
    _filter = filter.copyWith(category: _category);
    _page = 0;
    await _load();
  }

  Future<void> refresh() async {
    state = ExploreLoading(category: _category);
    _page = 0;
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ExploreReady || !current.hasMore) return;
    _page++;
    final camera = ref.read(mapCameraProvider);
    final origin = _resolveOrigin();
    final result = await ref
        .read(exploreRepositoryProvider)
        .search(
          ExploreSearch(
            category: _category,
            filter: _filter,
            latitude: origin.latitude,
            longitude: origin.longitude,
            page: _page,
          ),
        );
    state = ExploreReady(
      places: [...current.places, ...result.places],
      category: _category,
      filter: _filter,
      totalCount: result.totalCount,
      hasMore: result.hasMore,
      isOffline: result.isOffline,
      zoom: camera.zoom,
    );
  }

  void selectPlace(ExplorePlace place) {
    final current = state;
    if (current is ExploreReady) {
      ref.read(exploreFavoritesRepositoryProvider).recordRecent(place);
      state = ExplorePlaceSelected(place: place, previous: current);
      ref
          .read(mapFlyToTargetProvider.notifier)
          .flyTo(
            latitude: place.latitude,
            longitude: place.longitude,
            zoom: 15,
          );
    }
  }

  void selectFromSearch(SearchPlace place) {
    final explorePlace = ExplorePlace(
      id: place.id,
      name: place.name,
      category: _category ?? ExploreCategory.touristAttraction,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
    );
    selectPlace(explorePlace);
  }

  void dismissPlace() {
    final current = state;
    if (current is ExplorePlaceSelected) {
      state = current.previous;
    }
  }

  Future<void> _load() async {
    try {
      await _ensureLocation();
      final camera = ref.read(mapCameraProvider);
      final origin = _resolveOrigin();
      final result = await ref
          .read(exploreRepositoryProvider)
          .search(
            ExploreSearch(
              category: _category,
              filter: _filter,
              latitude: origin.latitude,
              longitude: origin.longitude,
              page: _page,
            ),
          );
      state = ExploreReady(
        places: result.places,
        category: _category,
        filter: _filter,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
        isOffline: result.isOffline,
        zoom: camera.zoom,
      );
    } catch (e) {
      state = ExploreError(message: e.toString());
    }
  }
}

// —— Map markers ——————————————————————————————————————————————————————————————

final exploreMapMarkersProvider = Provider<List<ExploreMarker>>((ref) {
  final active = ref.watch(exploreActiveProvider);
  if (!active) return const [];

  final exploreState = ref.watch(exploreControllerProvider);
  final camera = ref.watch(mapCameraProvider);
  final places = switch (exploreState) {
    ExploreReady(:final places) => places,
    ExplorePlaceSelected(:final previous) => previous.places,
    _ => const <ExplorePlace>[],
  };

  return ref
      .read(exploreServiceProvider)
      .clusterMarkers(places: places, zoom: camera.zoom);
});

// —— Journey recommendations ——————————————————————————————————————————————————

final exploreJourneyRecommendationsProvider =
    FutureProvider<List<ExploreJourneyRecommendation>>((ref) async {
      final journeyState = ref.watch(journeyControllerProvider);
      final liveState = ref.watch(liveJourneyControllerProvider);
      final camera = ref.watch(mapCameraProvider);

      JourneyMetrics? metrics;
      var trafficHeavy = false;
      var weatherAdverse = false;

      if (journeyState is JourneyPreview) {
        metrics = journeyState.summary.metrics;
        trafficHeavy = metrics.trafficLevel == TrafficLevel.heavy;
        weatherAdverse =
            metrics.temperatureCelsius > 42 ||
            metrics.weatherSummary.toLowerCase().contains('rain');
      } else if (liveState is LiveJourneyActive) {
        trafficHeavy = true;
      }

      if (metrics == null && liveState is! LiveJourneyActive) {
        return [];
      }

      final fuelPercent = metrics != null
          ? (100 - metrics.fuelEstimateLiters * 2).clamp(0, 100).toDouble()
          : 50.0;
      final batteryPercent = metrics != null
          ? (100 - metrics.batteryEstimatePercent).clamp(0, 100).toDouble()
          : 60.0;

      return ref
          .read(exploreRepositoryProvider)
          .getJourneyRecommendations(
            latitude: camera.latitude,
            longitude: camera.longitude,
            remainingFuelPercent: fuelPercent,
            remainingBatteryPercent: batteryPercent,
            journeyDurationMinutes: metrics?.durationMinutes,
            trafficHeavy: trafficHeavy,
            weatherAdverse: weatherAdverse,
          );
    });
