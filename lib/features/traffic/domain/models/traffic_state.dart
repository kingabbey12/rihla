import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/errors/traffic_failure.dart';

sealed class TrafficState {
  const TrafficState();
}

final class TrafficIdle extends TrafficState {
  const TrafficIdle();
}

final class TrafficLoading extends TrafficState {
  const TrafficLoading();
}

final class TrafficReady extends TrafficState {
  const TrafficReady(this.snapshot);
  final TrafficSnapshot snapshot;
}

final class TrafficError extends TrafficState {
  const TrafficError(this.failure);
  final TrafficFailure failure;
}
