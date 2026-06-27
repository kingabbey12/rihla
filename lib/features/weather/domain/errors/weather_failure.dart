/// Weather data access failures.
sealed class WeatherFailure implements Exception {
  const WeatherFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

final class WeatherServiceFailure extends WeatherFailure {
  const WeatherServiceFailure(super.message);
}

final class WeatherOfflineFailure extends WeatherFailure {
  const WeatherOfflineFailure() : super('Weather data unavailable offline');
}
