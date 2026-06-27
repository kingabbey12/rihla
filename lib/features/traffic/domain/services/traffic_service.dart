import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';

abstract class TrafficService {
  Future<TrafficSnapshot> getTrafficAlongRoute({
    required List<({double latitude, double longitude})> coordinates,
    required double freeFlowDurationMinutes,
  });
}
