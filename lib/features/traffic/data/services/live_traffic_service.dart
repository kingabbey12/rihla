import 'package:rihla/features/traffic/data/datasources/traffic_datasource.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/services/traffic_service.dart';

/// Production traffic service — TomTom when configured, heuristic fallback.
class LiveTrafficService implements TrafficService {
  LiveTrafficService(this._tomtom, this._heuristic);

  final TomTomTrafficDatasource _tomtom;
  final HeuristicTrafficDatasource _heuristic;

  @override
  Future<TrafficSnapshot> getTrafficAlongRoute({
    required List<({double latitude, double longitude})> coordinates,
    required double freeFlowDurationMinutes,
  }) async {
    if (_tomtom.isConfigured && coordinates.isNotEmpty) {
      final mid = coordinates[coordinates.length ~/ 2];
      try {
        return await _tomtom.fetchFlow(
          latitude: mid.latitude,
          longitude: mid.longitude,
          freeFlowDurationMinutes: freeFlowDurationMinutes,
        );
      } catch (_) {
        // Fall through to heuristic on TomTom failure.
      }
    }

    return _heuristic.estimate(
      coordinates: coordinates,
      freeFlowDurationMinutes: freeFlowDurationMinutes,
    );
  }
}
