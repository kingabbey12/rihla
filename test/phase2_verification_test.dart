import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/data/app_preferences_repository.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/launch/data/onboarding_pages_registry.dart';
import 'package:rihla/features/launch/data/permission_requests_registry.dart';
import 'package:rihla/localization/locale_provider.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/theme/theme_provider.dart';

void main() {
  group('Phase 2 verification', () {
    late SharedPreferences prefs;
    late AppPreferencesRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = AppPreferencesRepository(prefs);
    });

    test('onboarding registry is dynamic and has four pages', () {
      expect(OnboardingPagesRegistry.pages.length, 4);
    });

    test('permission registry is modular and has five requests', () {
      expect(PermissionRequestsRegistry.requests.length, 5);
    });

    test('persists and restores theme mode', () async {
      await repository.setThemeMode(ThemeMode.dark);
      expect(repository.getThemeMode(), ThemeMode.dark);
    });

    test('persists and restores locale', () async {
      await repository.setLocale(const Locale('ar'));
      expect(repository.getLocale().languageCode, 'ar');
    });

    test('persists onboarding completion', () async {
      expect(repository.onboardingCompleted, false);
      await repository.setOnboardingCompleted(true);
      expect(repository.onboardingCompleted, true);
    });

    test('persists launch flow completion', () async {
      expect(repository.launchFlowCompleted, false);
      await repository.setLaunchFlowCompleted(true);
      expect(repository.launchFlowCompleted, true);
    });

    testWidgets('launch flow redirects to the map experience when complete',
        (tester) async {
      SharedPreferences.setMockInitialValues({'launch_flow_completed': true});
      final completedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(completedPrefs),
          ],
          child: const App(),
        ),
      );
      // One frame applies the redirect; we assert on the router target instead
      // of settling because the map page hosts a native surface.
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final router = container.read(appRouterProvider);
      expect(router.state.matchedLocation, RoutePaths.maps);
    });

    testWidgets('fresh launch starts at native splash route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const App(),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final router = container.read(appRouterProvider);
      expect(router.state.matchedLocation, RoutePaths.splash);
    });
  });

  group('Theme and locale notifiers persist changes', () {
    test('locale notifier saves to preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('ar'));

      expect(prefs.getString('locale_code'), 'ar');
    });

    test('theme notifier saves to preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

      expect(prefs.getString('theme_mode'), 'dark');
    });
  });
}
