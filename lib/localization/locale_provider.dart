import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/data/app_preferences_repository.dart';
import 'package:rihla/core/providers/app_providers.dart';

/// Manages the active application [Locale] with persistence.
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  late AppPreferencesRepository _repository;

  @override
  Locale build() {
    _repository = ref.read(appPreferencesRepositoryProvider);
    return _repository.getLocale();
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _repository.setLocale(locale);
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    await setLocale(next);
  }
}
