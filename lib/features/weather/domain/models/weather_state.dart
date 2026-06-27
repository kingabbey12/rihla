import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/errors/weather_failure.dart';

/// Weather query state machine.
sealed class WeatherState {
  const WeatherState();
}

final class WeatherIdle extends WeatherState {
  const WeatherIdle();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

final class WeatherReady extends WeatherState {
  const WeatherReady(this.snapshot);
  final WeatherSnapshot snapshot;
}

final class WeatherError extends WeatherState {
  const WeatherError(this.failure);
  final WeatherFailure failure;
}
