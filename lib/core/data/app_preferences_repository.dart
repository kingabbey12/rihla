import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores user preferences across app launches.
class AppPreferencesRepository {
  AppPreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLocale = 'locale_code';
  static const _keyThemeMode = 'theme_mode';
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyLaunchFlowCompleted = 'launch_flow_completed';
  static const _keyHighContrast = 'high_contrast_enabled';

  Locale getLocale() {
    final code = _prefs.getString(_keyLocale) ?? 'en';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_keyThemeMode, value);
  }

  bool get onboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool get highContrastEnabled =>
      _prefs.getBool(_keyHighContrast) ?? false;

  Future<void> setHighContrastEnabled(bool value) async {
    await _prefs.setBool(_keyHighContrast, value);
  }

  bool get launchFlowCompleted =>
      _prefs.getBool(_keyLaunchFlowCompleted) ?? false;

  Future<void> setLaunchFlowCompleted(bool value) async {
    await _prefs.setBool(_keyLaunchFlowCompleted, value);
  }

  /// Clears launch state for testing.
  Future<void> clearLaunchState() async {
    await _prefs.remove(_keyOnboardingCompleted);
    await _prefs.remove(_keyLaunchFlowCompleted);
  }
}
