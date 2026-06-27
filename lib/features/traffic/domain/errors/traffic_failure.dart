sealed class TrafficFailure implements Exception {
  const TrafficFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

final class TrafficServiceFailure extends TrafficFailure {
  const TrafficServiceFailure(super.message);
}

final class TrafficOfflineFailure extends TrafficFailure {
  const TrafficOfflineFailure() : super('Traffic data unavailable offline');
}
