import 'package:rihla/features/explore/data/catalog/explore_place_catalog.dart';
import 'package:rihla/features/explore/data/datasources/overpass_poi_datasource.dart';
import 'package:rihla/features/explore/data/utils/explore_geo_util.dart';
import 'package:rihla/features/explore/data/utils/explore_marker_clusterer.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_marker.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_result.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/explore/domain/services/explore_service.dart';
import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/repositories/ev_charging_repository.dart';
import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/repositories/parking_repository.dart';
import 'package:rihla/features/offline/data/poi/offline_poi_catalog.dart';
import 'package:rihla/features/offline/domain/repositories/offline_repository.dart';

/// Aggregates live POI modules and offline POIs for Explore.
class ExploreServiceImpl implements ExploreService {
  ExploreServiceImpl({
    required OfflineRepository offlineRepository,
    required FuelRepository fuelRepository,
    required EvChargingRepository evChargingRepository,
    required ParkingRepository parkingRepository,
    required OverpassPoiDatasource poiDatasource,
    required bool Function() isOffline,
  }) : _offlineRepository = offlineRepository,
       _fuelRepository = fuelRepository,
       _evRepository = evChargingRepository,
       _parkingRepository = parkingRepository,
       _poiDatasource = poiDatasource,
       _isOffline = isOffline;

  final OfflineRepository _offlineRepository;
  final FuelRepository _fuelRepository;
  final EvChargingRepository _evRepository;
  final ParkingRepository _parkingRepository;
  final OverpassPoiDatasource _poiDatasource;
  final bool Function() _isOffline;

  @override
  Future<ExploreResult> search(ExploreSearch search) async {
    final originLat = search.latitude ?? 25.2048;
    final originLng = search.longitude ?? 55.2708;
    final all = await _loadPlaces(
      latitude: originLat,
      longitude: originLng,
      category: search.category ?? search.filter.category,
      radiusKm: search.filter.maxDistanceKm,
    );

    var filtered = all.where(search.filter.matches).toList();

    if (search.query != null && search.query!.trim().isNotEmpty) {
      final q = search.query!.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q),
          )
          .toList();
    }

    if (search.viewportNorth != null) {
      filtered = filtered
          .where(
            (p) => ExploreGeoUtil.inViewport(
              latitude: p.latitude,
              longitude: p.longitude,
              north: search.viewportNorth,
              south: search.viewportSouth,
              east: search.viewportEast,
              west: search.viewportWest,
            ),
          )
          .toList();
    }

    filtered = _withDistance(filtered, originLat, originLng);
    filtered.sort(
      (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
    );

    final start = search.page * search.pageSize;
    final end = (start + search.pageSize).clamp(0, filtered.length);
    final pageItems = start < filtered.length
        ? filtered.sublist(start, end)
        : <ExplorePlace>[];

    return ExploreResult(
      places: pageItems,
      totalCount: filtered.length,
      page: search.page,
      pageSize: search.pageSize,
      hasMore: end < filtered.length,
      isOffline: _isOffline(),
    );
  }

  @override
  Future<List<ExplorePlace>> getPlacesByCategory({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 50,
  }) async {
    final all = await _loadPlaces(
      latitude: latitude,
      longitude: longitude,
      category: category,
      radiusKm: radiusKm,
    );
    final withDistance = _withDistance(all, latitude, longitude);
    withDistance.sort(
      (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
    );
    return withDistance.take(limit).toList();
  }

  @override
  Future<List<ExploreJourneyRecommendation>> getJourneyRecommendations({
    required double latitude,
    required double longitude,
    double? remainingFuelPercent,
    double? remainingBatteryPercent,
    int? journeyDurationMinutes,
    bool trafficHeavy = false,
    bool weatherAdverse = false,
  }) async {
    final recommendations = <ExploreJourneyRecommendation>[];
    var priority = 0;

    final fuelLow = remainingFuelPercent != null && remainingFuelPercent < 25;
    final batteryLow =
        remainingBatteryPercent != null && remainingBatteryPercent < 20;
    final longTrip =
        journeyDurationMinutes != null && journeyDurationMinutes > 90;

    if (fuelLow) {
      final places = await getPlacesByCategory(
        category: ExploreCategory.fuelStation,
        latitude: latitude,
        longitude: longitude,
        radiusKm: 30,
        limit: 3,
      );
      recommendations.add(
        ExploreJourneyRecommendation(
          places: places,
          reason: 'Fuel level is low — nearby stations recommended',
          category: ExploreCategory.fuelStation,
          priority: priority++,
        ),
      );
    }

    if (batteryLow) {
      final places = await getPlacesByCategory(
        category: ExploreCategory.evCharger,
        latitude: latitude,
        longitude: longitude,
        radiusKm: 25,
        limit: 3,
      );
      recommendations.add(
        ExploreJourneyRecommendation(
          places: places,
          reason: 'Battery charge is low — charging stops nearby',
          category: ExploreCategory.evCharger,
          priority: priority++,
        ),
      );
    }

    if (longTrip || trafficHeavy) {
      final coffee = await getPlacesByCategory(
        category: ExploreCategory.coffeeShop,
        latitude: latitude,
        longitude: longitude,
        limit: 2,
      );
      recommendations.add(
        ExploreJourneyRecommendation(
          places: coffee,
          reason: trafficHeavy
              ? 'Heavy traffic — consider a coffee break'
              : 'Long journey — rest stop suggested',
          category: ExploreCategory.coffeeShop,
          priority: priority++,
        ),
      );
    }

    if (weatherAdverse || longTrip) {
      final restaurants = await getPlacesByCategory(
        category: ExploreCategory.restaurant,
        latitude: latitude,
        longitude: longitude,
        limit: 2,
      );
      recommendations.add(
        ExploreJourneyRecommendation(
          places: restaurants,
          reason: weatherAdverse
              ? 'Adverse weather — indoor dining nearby'
              : 'Meal break recommended on this route',
          category: ExploreCategory.restaurant,
          priority: priority++,
        ),
      );
    }

    if (trafficHeavy) {
      final parking = await getPlacesByCategory(
        category: ExploreCategory.parking,
        latitude: latitude,
        longitude: longitude,
        limit: 2,
      );
      recommendations.add(
        ExploreJourneyRecommendation(
          places: parking,
          reason: 'Rest areas and parking near your route',
          category: ExploreCategory.parking,
          priority: priority++,
        ),
      );
    }

    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return recommendations;
  }

  @override
  List<ExploreMarker> clusterMarkers({
    required List<ExplorePlace> places,
    required double zoom,
    double? north,
    double? south,
    double? east,
    double? west,
  }) => ExploreMarkerClusterer.cluster(
    places: places,
    zoom: zoom,
    north: north,
    south: south,
    east: east,
    west: west,
  );

  Future<List<ExplorePlace>> _loadPlaces({
    required double latitude,
    required double longitude,
    ExploreCategory? category,
    required double radiusKm,
  }) async {
    if (_isOffline()) {
      return _loadOfflinePlaces(category: category);
    }

    final categories = category == null ? ExploreCategory.values : [category];
    var places = <ExplorePlace>[];

    for (final c in categories) {
      final livePois = await _poiDatasource.fetchNearby(
        category: c,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      places = [...places, ...livePois];
    }

    try {
      final liveFuel = await _fuelRepository.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      places = [...places, ...liveFuel.map(_fromFuelStation)];
    } catch (_) {}

    try {
      final liveEv = await _evRepository.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      places = [...places, ...liveEv.map(_fromEvCharger)];
    } catch (_) {}

    try {
      final liveParking = await _parkingRepository.findNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      places = [...places, ...liveParking.map(_fromParking)];
    } catch (_) {}

    if (category != null) {
      places = places.where((p) => p.category == category).toList();
    }
    return places;
  }

  Future<List<ExplorePlace>> _loadOfflinePlaces({
    ExploreCategory? category,
  }) async {
    final regions = await _offlineRepository.getDownloadedRegions();
    final places = <ExplorePlace>[];
    for (final region in regions) {
      for (final poi in OfflinePoiCatalog.poisForRegion(region)) {
        final place = ExplorePlaceCatalog.fromSearchPlace(poi);
        if (category == null || place.category == category) {
          places.add(place);
        }
      }
    }
    if (places.isEmpty) {
      return const [];
    }
    return places;
  }

  List<ExplorePlace> _withDistance(
    List<ExplorePlace> places,
    double lat,
    double lng,
  ) => places.map((p) {
    final km = ExploreGeoUtil.distanceKm(lat, lng, p.latitude, p.longitude);
    return ExplorePlace(
      id: p.id,
      name: p.name,
      category: p.category,
      latitude: p.latitude,
      longitude: p.longitude,
      address: p.address,
      rating: p.rating,
      reviewCount: p.reviewCount,
      openingHours: p.openingHours,
      isOpenNow: p.isOpenNow,
      isOpen24Hours: p.isOpen24Hours,
      phone: p.phone,
      website: p.website,
      photoUrl: p.photoUrl,
      distanceKm: km,
      etaMinutes: ExploreGeoUtil.etaMinutes(km),
      fuelTypes: p.fuelTypes,
      evConnectorTypes: p.evConnectorTypes,
      isFreeParking: p.isFreeParking,
      isPaidParking: p.isPaidParking,
      isAccessible: p.isAccessible,
      isFamilyFriendly: p.isFamilyFriendly,
      priceLevel: p.priceLevel,
    );
  }).toList();

  ExplorePlace _fromFuelStation(FuelStation s) => ExplorePlace(
    id: 'fuel_${s.id}',
    name: s.name,
    category: ExploreCategory.fuelStation,
    latitude: s.latitude,
    longitude: s.longitude,
    address: s.name,
    distanceKm: s.distanceKm,
    isOpenNow: s.isOpen,
    fuelTypes: [s.fuelType],
  );

  ExplorePlace _fromEvCharger(EvCharger c) => ExplorePlace(
    id: 'ev_${c.id}',
    name: c.name,
    category: ExploreCategory.evCharger,
    latitude: c.latitude,
    longitude: c.longitude,
    address: c.operatorName ?? c.name,
    distanceKm: c.distanceKm,
    isOpenNow: c.isAvailable,
    evConnectorTypes: c.connectorTypes,
  );

  ExplorePlace _fromParking(ParkingLocation p) => ExplorePlace(
    id: 'parking_${p.id}',
    name: p.name,
    category: ExploreCategory.parking,
    latitude: p.latitude,
    longitude: p.longitude,
    address: p.name,
    distanceKm: p.distanceKm,
    isOpenNow: p.isAvailable,
    isPaidParking: p.pricePerHour > 0,
    isFreeParking: p.pricePerHour == 0,
    openingHours: p.openingHours,
  );
}
