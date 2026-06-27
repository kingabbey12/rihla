import 'package:rihla/features/offline/data/catalog/uae_offline_regions.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Seed POI data bundled per UAE region for offline search.
abstract final class OfflinePoiCatalog {
  static List<SearchPlace> poisForRegion(OfflineRegion region) {
    return switch (region.id) {
      'uae_dubai' => _dubaiPois,
      'uae_abu_dhabi' => _abuDhabiPois,
      'uae_sharjah' => _sharjahPois,
      _ => _genericPois(region),
    };
  }

  static final _dubaiPois = [
    const SearchPlace(
      id: 'offline_dubai_marina',
      name: 'Dubai Marina',
      address: 'Dubai Marina, Dubai',
      latitude: 25.0805,
      longitude: 55.1403,
      category: 'landmark',
    ),
    const SearchPlace(
      id: 'offline_dubai_mall',
      name: 'The Dubai Mall',
      address: 'Downtown Dubai',
      latitude: 25.1972,
      longitude: 55.2796,
      category: 'mall',
    ),
    const SearchPlace(
      id: 'offline_dx_b_airport',
      name: 'Dubai International Airport',
      address: 'Garhoud, Dubai',
      latitude: 25.2532,
      longitude: 55.3657,
      category: 'airport',
    ),
    const SearchPlace(
      id: 'offline_jbr',
      name: 'JBR Beach',
      address: 'Jumeirah Beach Residence',
      latitude: 25.0772,
      longitude: 55.1334,
      category: 'landmark',
    ),
  ];

  static final _abuDhabiPois = [
    const SearchPlace(
      id: 'offline_ad_corniche',
      name: 'Abu Dhabi Corniche',
      address: 'Corniche Road, Abu Dhabi',
      latitude: 24.4857,
      longitude: 54.3540,
      category: 'landmark',
    ),
    const SearchPlace(
      id: 'offline_yas_mall',
      name: 'Yas Mall',
      address: 'Yas Island, Abu Dhabi',
      latitude: 24.4889,
      longitude: 54.6077,
      category: 'mall',
    ),
    const SearchPlace(
      id: 'offline_auh_airport',
      name: 'Abu Dhabi International Airport',
      address: 'Abu Dhabi',
      latitude: 24.4330,
      longitude: 54.6511,
      category: 'airport',
    ),
  ];

  static final _sharjahPois = [
    const SearchPlace(
      id: 'offline_shj_city_centre',
      name: 'City Centre Sharjah',
      address: 'Al Wahda Road, Sharjah',
      latitude: 25.3328,
      longitude: 55.4201,
      category: 'mall',
    ),
    const SearchPlace(
      id: 'offline_shj_airport',
      name: 'Sharjah International Airport',
      address: 'Sharjah',
      latitude: 25.3285,
      longitude: 55.5172,
      category: 'airport',
    ),
  ];

  static List<SearchPlace> _genericPois(OfflineRegion region) => [
        SearchPlace(
          id: 'offline_${region.id}_center',
          name: '${region.name} City Center',
          address: region.name,
          latitude: region.centerLatitude,
          longitude: region.centerLongitude,
          category: 'landmark',
        ),
      ];
}
