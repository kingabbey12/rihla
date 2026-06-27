import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/repositories/traffic_repository.dart';
import 'package:rihla/features/traffic/domain/services/traffic_service.dart';

class TrafficRepositoryImpl implements TrafficRepository {
  TrafficRepositoryImpl(this._service);

  final TrafficService _service;

  @override
  Future<TrafficSnapshot> getTrafficAlongRoute({
    required List<({double latitude, double longitude})> coordinates,
    required double freeFlowDurationMinutes,
  }) =>
      _service.getTrafficAlongRoute(
        coordinates: coordinates,
        freeFlowDurationMinutes: freeFlowDurationMinutes,
      );
}
