import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/localization/locale_provider.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:rihla/theme/theme_provider.dart';

void main() {
  group('Phase 1 verification', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'launch_flow_completed': true});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const App(),
        ),
      );
      // Single frame only: launch is complete so the app redirects to the map
      // experience, whose native surface and loading indicator never settle.
      await tester.pump();
    }

    testWidgets('Riverpod is initialized and providers are readable', (tester) async {
      await pumpApp(tester);

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(container.read(localeProvider), const Locale('en'));
      expect(container.read(appRouterProvider), isA<GoRouter>());
    });

    testWidgets('go_router includes launch and core routes', (tester) async {
      await pumpApp(tester);

      final router = container.read(appRouterProvider);
      expect(router.configuration.routes.length, greaterThanOrEqualTo(12));
    });

    testWidgets('Theme switching updates theme mode', (tester) async {
      await pumpApp(tester);

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme, AppTheme.dark);
    });

    testWidgets('Localization switches between English and Arabic', (tester) async {
      await pumpApp(tester);

      await container.read(localeProvider.notifier).setLocale(const Locale('ar'));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale?.languageCode, 'ar');
    });
  });
}
