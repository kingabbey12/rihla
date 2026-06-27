import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/network_providers.dart';
import 'package:rihla/features/weather/data/datasources/open_meteo_datasource.dart';
import 'package:rihla/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:rihla/features/weather/data/services/open_meteo_weather_service.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/errors/weather_failure.dart';
import 'package:rihla/features/weather/domain/models/weather_state.dart';
import 'package:rihla/features/weather/domain/repositories/weather_repository.dart';
import 'package:rihla/features/weather/domain/services/weather_service.dart';

final openMeteoDatasourceProvider = Provider<OpenMeteoDatasource>(
  (ref) => OpenMeteoDatasource(ref.watch(apiClientProvider)),
);

final weatherServiceProvider = Provider<WeatherService>(
  (ref) => OpenMeteoWeatherService(ref.watch(openMeteoDatasourceProvider)),
);

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepositoryImpl(ref.watch(weatherServiceProvider)),
);

/// Central weather state — fetches on demand for a location.
final weatherControllerProvider =
    NotifierProvider<WeatherController, WeatherState>(WeatherController.new);

class WeatherController extends Notifier<WeatherState> {
  @override
  WeatherState build() => const WeatherIdle();

  Future<void> fetch({required double latitude, required double longitude}) async {
    state = const WeatherLoading();
    try {
      final snapshot = await ref.read(weatherRepositoryProvider).getWeather(
            latitude: latitude,
            longitude: longitude,
          );
      state = WeatherReady(snapshot);
    } on WeatherFailure catch (failure) {
      state = WeatherError(failure);
    } catch (e) {
      state = WeatherError(WeatherServiceFailure(e.toString()));
    }
  }

  void reset() => state = const WeatherIdle();
}

final weatherSnapshotProvider = Provider<WeatherSnapshot?>((ref) {
  final s = ref.watch(weatherControllerProvider);
  return s is WeatherReady ? s.snapshot : null;
});

final weatherTemperatureProvider = Provider<double?>((ref) {
  return ref.watch(weatherSnapshotProvider)?.current.temperatureCelsius;
});

final weatherSummaryProvider = Provider<String?>((ref) {
  return ref.watch(weatherSnapshotProvider)?.current.summary;
});
