import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/data/app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the singleton [SharedPreferences] instance, overridden in [main].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>(
  (ref) => AppPreferencesRepository(ref.watch(sharedPreferencesProvider)),
);
