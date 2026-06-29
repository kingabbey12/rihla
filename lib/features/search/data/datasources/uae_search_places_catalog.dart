import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Curated UAE seed places for offline fallback and empty-query suggestions.
///
/// Live search uses Nominatim with UAE bias; this catalog is only used when
/// offline or when the network returns no results.
abstract final class UaeSearchPlacesCatalog {
  /// UAE bounding box used to bias Nominatim: west, south, east, north.
  static const uaeViewbox = '51.5,22.5,56.5,26.5';
  static const countryCode = 'ae';

  static const List<SearchPlace> all = [
    SearchPlace(
      id: 'uae_dubai_mall',
      name: 'Dubai Mall',
      address: 'Financial Center Rd, Downtown Dubai, Dubai',
      latitude: 25.1972,
      longitude: 55.2796,
      category: 'mall',
    ),
    SearchPlace(
      id: 'uae_burj_khalifa',
      name: 'Burj Khalifa',
      address: '1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai',
      latitude: 25.1972,
      longitude: 55.2744,
      category: 'landmark',
    ),
    SearchPlace(
      id: 'uae_palm_jumeirah',
      name: 'Palm Jumeirah',
      address: 'Palm Jumeirah, Dubai',
      latitude: 25.1124,
      longitude: 55.1390,
      category: 'landmark',
    ),
    SearchPlace(
      id: 'uae_mall_of_emirates',
      name: 'Mall of the Emirates',
      address: 'Sheikh Zayed Rd, Al Barsha, Dubai',
      latitude: 25.1181,
      longitude: 55.2006,
      category: 'mall',
    ),
    SearchPlace(
      id: 'uae_dubai_marina',
      name: 'Dubai Marina',
      address: 'Dubai Marina, Dubai',
      latitude: 25.0805,
      longitude: 55.1403,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_business_bay',
      name: 'Business Bay',
      address: 'Business Bay, Dubai',
      latitude: 25.1850,
      longitude: 55.2650,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_downtown_dubai',
      name: 'Downtown Dubai',
      address: 'Downtown Dubai, Dubai',
      latitude: 25.1975,
      longitude: 55.2744,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_jvc',
      name: 'JVC',
      address: 'Jumeirah Village Circle, Dubai',
      latitude: 25.0600,
      longitude: 55.2100,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_al_barsha',
      name: 'Al Barsha',
      address: 'Al Barsha, Dubai',
      latitude: 25.1102,
      longitude: 55.2003,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_sheikh_zayed_road',
      name: 'Sheikh Zayed Road',
      address: 'Sheikh Zayed Rd, Dubai',
      latitude: 25.2048,
      longitude: 55.2708,
      category: 'street',
    ),
    SearchPlace(
      id: 'uae_expo_city',
      name: 'Expo City Dubai',
      address: 'Expo Road, Dubai South',
      latitude: 24.9607,
      longitude: 55.1503,
      category: 'landmark',
    ),
    SearchPlace(
      id: 'uae_global_village',
      name: 'Global Village',
      address: 'Sheikh Mohammed Bin Zayed Rd, Dubai',
      latitude: 25.0680,
      longitude: 55.3070,
      category: 'entertainment',
    ),
    SearchPlace(
      id: 'uae_dxb_airport',
      name: 'Dubai International Airport',
      address: 'Garhoud, Dubai',
      latitude: 25.2532,
      longitude: 55.3657,
      category: 'airport',
    ),
    SearchPlace(
      id: 'uae_yas_island',
      name: 'Yas Island',
      address: 'Yas Island, Abu Dhabi',
      latitude: 24.4889,
      longitude: 54.6077,
      category: 'landmark',
    ),
    SearchPlace(
      id: 'uae_marina_mall',
      name: 'Marina Mall',
      address: 'Corniche Rd, Abu Dhabi',
      latitude: 24.4750,
      longitude: 54.3210,
      category: 'mall',
    ),
    SearchPlace(
      id: 'uae_khalifa_city',
      name: 'Khalifa City',
      address: 'Khalifa City, Abu Dhabi',
      latitude: 24.4250,
      longitude: 54.6050,
      category: 'district',
    ),
    SearchPlace(
      id: 'uae_al_ain',
      name: 'Al Ain',
      address: 'Al Ain, Abu Dhabi',
      latitude: 24.2075,
      longitude: 55.7447,
      category: 'city',
    ),
    SearchPlace(
      id: 'uae_sharjah_city_centre',
      name: 'Sharjah City Centre',
      address: 'Al Wahda St, Sharjah',
      latitude: 25.3290,
      longitude: 55.4200,
      category: 'mall',
    ),
    SearchPlace(
      id: 'uae_ajman',
      name: 'Ajman',
      address: 'Ajman, UAE',
      latitude: 25.4052,
      longitude: 55.5136,
      category: 'city',
    ),
    SearchPlace(
      id: 'uae_ras_al_khaimah',
      name: 'Ras Al Khaimah',
      address: 'Ras Al Khaimah, UAE',
      latitude: 25.7895,
      longitude: 55.9432,
      category: 'city',
    ),
    SearchPlace(
      id: 'uae_fujairah',
      name: 'Fujairah',
      address: 'Fujairah, UAE',
      latitude: 25.1288,
      longitude: 56.3265,
      category: 'city',
    ),
    SearchPlace(
      id: 'uae_uaq',
      name: 'Umm Al Quwain',
      address: 'Umm Al Quwain, UAE',
      latitude: 25.5647,
      longitude: 55.5552,
      category: 'city',
    ),
    SearchPlace(
      id: 'uae_abu_dhabi_corniche',
      name: 'Abu Dhabi Corniche',
      address: 'Corniche Rd, Abu Dhabi',
      latitude: 24.4764,
      longitude: 54.3705,
      category: 'landmark',
    ),
  ];

  static List<SearchPlace> get popular => [
    all.firstWhere((p) => p.id == 'uae_dubai_mall'),
    all.firstWhere((p) => p.id == 'uae_burj_khalifa'),
    all.firstWhere((p) => p.id == 'uae_dubai_marina'),
    all.firstWhere((p) => p.id == 'uae_mall_of_emirates'),
    all.firstWhere((p) => p.id == 'uae_yas_island'),
    all.firstWhere((p) => p.id == 'uae_dxb_airport'),
  ];

  static List<SearchPlace> search(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return popular;
    return all
        .where(
          (p) =>
              p.name.toLowerCase().contains(trimmed) ||
              p.address.toLowerCase().contains(trimmed) ||
              (p.category?.toLowerCase().contains(trimmed) ?? false),
        )
        .toList();
  }
}
