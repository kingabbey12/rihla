import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';

/// Predefined UAE emirate download regions.
abstract final class UaeOfflineRegions {
  static const _version = '1.0.0';

  static const abuDhabi = OfflineRegion(
    id: 'uae_abu_dhabi',
    name: 'Abu Dhabi',
    type: OfflineRegionType.emirate,
    minLatitude: 23.5,
    minLongitude: 51.0,
    maxLatitude: 24.8,
    maxLongitude: 55.0,
    estimatedSizeMb: 420,
    version: _version,
    description: 'Abu Dhabi emirate offline maps',
  );

  static const dubai = OfflineRegion(
    id: 'uae_dubai',
    name: 'Dubai',
    type: OfflineRegionType.emirate,
    minLatitude: 24.8,
    minLongitude: 54.8,
    maxLatitude: 25.4,
    maxLongitude: 55.6,
    estimatedSizeMb: 380,
    version: _version,
    description: 'Dubai emirate offline maps',
  );

  static const sharjah = OfflineRegion(
    id: 'uae_sharjah',
    name: 'Sharjah',
    type: OfflineRegionType.emirate,
    minLatitude: 25.0,
    minLongitude: 55.3,
    maxLatitude: 25.5,
    maxLongitude: 56.0,
    estimatedSizeMb: 180,
    version: _version,
  );

  static const ajman = OfflineRegion(
    id: 'uae_ajman',
    name: 'Ajman',
    type: OfflineRegionType.emirate,
    minLatitude: 25.35,
    minLongitude: 55.4,
    maxLatitude: 25.45,
    maxLongitude: 55.55,
    estimatedSizeMb: 45,
    version: _version,
  );

  static const rasAlKhaimah = OfflineRegion(
    id: 'uae_ras_al_khaimah',
    name: 'Ras Al Khaimah',
    type: OfflineRegionType.emirate,
    minLatitude: 25.5,
    minLongitude: 55.8,
    maxLatitude: 26.1,
    maxLongitude: 56.2,
    estimatedSizeMb: 160,
    version: _version,
  );

  static const fujairah = OfflineRegion(
    id: 'uae_fujairah',
    name: 'Fujairah',
    type: OfflineRegionType.emirate,
    minLatitude: 25.0,
    minLongitude: 56.2,
    maxLatitude: 25.7,
    maxLongitude: 56.5,
    estimatedSizeMb: 120,
    version: _version,
  );

  static const ummAlQuwain = OfflineRegion(
    id: 'uae_umm_al_quwain',
    name: 'Umm Al Quwain',
    type: OfflineRegionType.emirate,
    minLatitude: 25.5,
    minLongitude: 55.5,
    maxLatitude: 25.65,
    maxLongitude: 55.8,
    estimatedSizeMb: 40,
    version: _version,
  );

  static const all = [
    abuDhabi,
    dubai,
    sharjah,
    ajman,
    rasAlKhaimah,
    fujairah,
    ummAlQuwain,
  ];

  static OfflineRegion? findById(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static OfflineRegion? regionContaining(double lat, double lon) {
    for (final r in all) {
      if (r.contains(lat, lon)) return r;
    }
    return null;
  }
}
