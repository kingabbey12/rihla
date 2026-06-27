import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';

/// A downloadable geographic region (emirate, custom, or drawn area).
class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.name,
    required this.type,
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
    required this.estimatedSizeMb,
    this.version = '1.0.0',
    this.description,
  });

  final String id;
  final String name;
  final OfflineRegionType type;
  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
  final int estimatedSizeMb;
  final String version;
  final String? description;

  double get centerLatitude => (minLatitude + maxLatitude) / 2;
  double get centerLongitude => (minLongitude + maxLongitude) / 2;

  bool contains(double lat, double lon) =>
      lat >= minLatitude &&
      lat <= maxLatitude &&
      lon >= minLongitude &&
      lon <= maxLongitude;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'minLatitude': minLatitude,
        'minLongitude': minLongitude,
        'maxLatitude': maxLatitude,
        'maxLongitude': maxLongitude,
        'estimatedSizeMb': estimatedSizeMb,
        'version': version,
        if (description != null) 'description': description,
      };

  factory OfflineRegion.fromJson(Map<String, dynamic> json) => OfflineRegion(
        id: json['id'] as String,
        name: json['name'] as String,
        type: OfflineRegionType.values.byName(json['type'] as String),
        minLatitude: (json['minLatitude'] as num).toDouble(),
        minLongitude: (json['minLongitude'] as num).toDouble(),
        maxLatitude: (json['maxLatitude'] as num).toDouble(),
        maxLongitude: (json['maxLongitude'] as num).toDouble(),
        estimatedSizeMb: json['estimatedSizeMb'] as int,
        version: json['version'] as String? ?? '1.0.0',
        description: json['description'] as String?,
      );
}
