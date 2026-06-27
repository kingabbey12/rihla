import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/data/app_preferences_repository.dart';
import 'package:rihla/core/providers/app_providers.dart';

/// Manages the active [ThemeMode] with persistence.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  late AppPreferencesRepository _repository;

  @override
  ThemeMode build() {
    _repository = ref.read(appPreferencesRepositoryProvider);
    return _repository.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repository.setThemeMode(mode);
  }

  Future<void> toggleLightDark() async {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    await setThemeMode(next);
  }
}
