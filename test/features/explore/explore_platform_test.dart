import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/repositories/ev_charging_repository.dart';
import 'package:rihla/features/explore/data/datasources/overpass_poi_datasource.dart';
import 'package:rihla/features/explore/data/datasources/explore_favorites_local_datasource.dart';
import 'package:rihla/features/explore/data/repositories/explore_favorites_repository_impl.dart';
import 'package:rihla/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:rihla/features/explore/data/services/explore_service_impl.dart';
import 'package:rihla/features/explore/data/utils/explore_marker_clusterer.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_filter.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:rihla/features/offline/data/catalog/uae_offline_regions.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/repositories/offline_repository.dart';
import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/repositories/parking_repository.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ExploreServiceImpl buildService({
    bool offline = false,
    bool downloaded = false,
  }) {
    return ExploreServiceImpl(
      offlineRepository: _FakeOfflineRepository(downloaded: downloaded),
      fuelRepository: _FakeFuelRepository(),
      evChargingRepository: _FakeEvRepository(),
      parkingRepository: _FakeParkingRepository(),
      poiDatasource: _FakePoiDatasource(),
      isOffline: () => offline,
    );
  }

  group('Marker clustering', () {
    test('clusters nearby places at low zoom', () {
      final places = _clusterFixturePlaces(20);
      final markers = ExploreMarkerClusterer.cluster(places: places, zoom: 10);
      expect(markers.length, lessThan(places.length));
      expect(markers.any((m) => m.isCluster), isTrue);
    });

    test('shows individual markers at high zoom', () {
      final places = _clusterFixturePlaces(5);
      final markers = ExploreMarkerClusterer.cluster(places: places, zoom: 16);
      expect(markers.every((m) => !m.isCluster), isTrue);
    });
  });

  group('Filtering', () {
    test('filter matches rating and open now', () {
      const filter = ExploreFilter(minRating: 4.0, openNow: true);
      const matching = ExplorePlace(
        id: 'a',
        name: 'Test',
        category: ExploreCategory.restaurant,
        latitude: 25.0,
        longitude: 55.0,
        address: 'UAE',
        rating: 4.5,
        isOpenNow: true,
        distanceKm: 5,
      );
      const nonMatching = ExplorePlace(
        id: 'b',
        name: 'Test',
        category: ExploreCategory.restaurant,
        latitude: 25.0,
        longitude: 55.0,
        address: 'UAE',
        rating: 3.0,
        isOpenNow: true,
        distanceKm: 5,
      );
      expect(filter.matches(matching), isTrue);
      expect(filter.matches(nonMatching), isFalse);
    });

    test('search applies filters and pagination', () async {
      final service = buildService();
      final result = await service.search(
        const ExploreSearch(
          category: ExploreCategory.restaurant,
          filter: ExploreFilter(maxDistanceKm: 50),
          latitude: 25.2,
          longitude: 55.27,
          pageSize: 3,
        ),
      );
      expect(result.places.length, lessThanOrEqualTo(3));
      expect(
        result.places.every((p) => p.category == ExploreCategory.restaurant),
        isTrue,
      );
    });
  });

  group('Offline Explore', () {
    test('uses offline POIs when offline mode active', () async {
      final service = buildService(offline: true, downloaded: true);
      final result = await service.search(
        const ExploreSearch(latitude: 25.2, longitude: 55.27),
      );
      expect(result.isOffline, isTrue);
      expect(result.places, isNotEmpty);
    });
  });

  group('Favorites', () {
    test('save, pin, and visit places', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ExploreFavoritesRepositoryImpl(
        ExploreFavoritesLocalDatasource(prefs),
      );
      const place = ExplorePlace(
        id: 'fav_1',
        name: 'Favorite Cafe',
        category: ExploreCategory.coffeeShop,
        latitude: 25.2,
        longitude: 55.27,
        address: 'Dubai',
      );
      await repo.savePlace(place);
      await repo.pinPlace(place);
      await repo.recordVisit(place);
      expect(repo.isSaved('fav_1'), isTrue);
      expect(repo.isPinned('fav_1'), isTrue);
      expect(repo.getVisitedPlaces().first.id, 'fav_1');
    });
  });

  group('Journey recommendations', () {
    test('recommends fuel when fuel is low', () async {
      final service = buildService();
      final recs = await service.getJourneyRecommendations(
        latitude: 25.2,
        longitude: 55.27,
        remainingFuelPercent: 15,
        journeyDurationMinutes: 120,
        trafficHeavy: true,
      );
      expect(
        recs.any((r) => r.category == ExploreCategory.fuelStation),
        isTrue,
      );
      expect(recs.any((r) => r.category == ExploreCategory.coffeeShop), isTrue);
    });
  });

  group('Search integration', () {
    test('explore controller selects place from search', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          exploreServiceProvider.overrideWith((ref) => buildService()),
          exploreRepositoryProvider.overrideWith(
            (ref) => ExploreRepositoryImpl(ref.watch(exploreServiceProvider)),
          ),
          safetyServiceProvider.overrideWithValue(MockSafetyService()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(exploreControllerProvider.notifier)
          .activate(initialCategory: ExploreCategory.coffeeShop);
      container
          .read(exploreControllerProvider.notifier)
          .selectFromSearch(
            const SearchPlace(
              id: 'search_1',
              name: 'Search Result',
              address: 'Dubai',
              latitude: 25.21,
              longitude: 55.26,
            ),
          );
      final state = container.read(exploreControllerProvider);
      expect(state, isA<ExplorePlaceSelected>());
      expect((state as ExplorePlaceSelected).place.name, 'Search Result');
    });
  });
}

List<ExplorePlace> _clusterFixturePlaces(int count) {
  return List.generate(
    count,
    (i) => ExplorePlace(
      id: 'place_$i',
      name: 'Dubai Place $i',
      category: ExploreCategory.restaurant,
      latitude: 25.20 + i * 0.01,
      longitude: 55.27 + i * 0.01,
      address: 'Dubai',
    ),
  );
}

class _FakePoiDatasource extends OverpassPoiDatasource {
  _FakePoiDatasource() : super(ApiClient());

  @override
  Future<List<ExplorePlace>> fetchNearby({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 40,
  }) async {
    if (category == ExploreCategory.coffeeShop) {
      return [
        ExplorePlace(
          id: 'osm_cafe',
          name: 'Dubai Coffee',
          category: category,
          latitude: latitude + 0.001,
          longitude: longitude + 0.001,
          address: 'Dubai',
        ),
      ];
    }
    if (category == ExploreCategory.restaurant) {
      return [
        ExplorePlace(
          id: 'osm_restaurant',
          name: 'Dubai Restaurant',
          category: category,
          latitude: latitude + 0.002,
          longitude: longitude + 0.002,
          address: 'Dubai',
        ),
      ];
    }
    return [];
  }
}

class _FakeOfflineRepository implements OfflineRepository {
  _FakeOfflineRepository({this.downloaded = false});

  final bool downloaded;

  @override
  Future<List<OfflineRegion>> getDownloadedRegions() async {
    if (!downloaded) return [];
    return [UaeOfflineRegions.dubai];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFuelRepository implements FuelRepository {
  @override
  Future<List<FuelStation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEvRepository implements EvChargingRepository {
  @override
  Future<List<EvCharger>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeParkingRepository implements ParkingRepository {
  @override
  Future<List<ParkingLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
