import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/driving/presentation/pages/rihla_drive_page.dart';
import 'package:rihla/features/emergency/presentation/pages/emergency_dashboard_page.dart';
import 'package:rihla/features/emergency/presentation/pages/report_incident_page.dart';
import 'package:rihla/features/explore/presentation/pages/explore_nearby_page.dart';
import 'package:rihla/features/launch/presentation/pages/welcome_page.dart';
import 'package:rihla/features/profile/presentation/pages/profile_page.dart';
import 'package:rihla/features/traffic/presentation/pages/traffic_incidents_page.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/navigation/navigation_test_helpers.dart';

late SharedPreferences _prefs;

Future<void> _loadRealFonts() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var loadedAny = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
      loadedAny = true;
    }
    if (loadedAny) await loader.load();
  }

  await loadFamily('Roboto', const [
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  await loadFamily('MaterialIcons', [
    if (flutterRoot != null)
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

Future<void> _capture(
  WidgetTester tester,
  Widget page,
  String file, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        ...navigationTestOverrides(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$file'),
  );
  // Drain async work before the next screen so disposed trees don't report overflow.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runAsync(_loadRealFonts);
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  Future<void> golden(
    WidgetTester tester,
    Widget page,
    String file, {
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _capture(tester, page, file, theme: theme);
  }

  testWidgets('welcome screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const WelcomePage(), 'screen_welcome.png', theme: AppTheme.dark);
  }, skip: !Platform.isMacOS);

  testWidgets('explore screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const ExploreNearbyPage(), 'screen_explore.png', theme: AppTheme.dark);
  }, skip: !Platform.isMacOS);

  testWidgets('emergency screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(
      tester,
      const EmergencyDashboardPage(),
      'screen_emergency.png',
      theme: AppTheme.dark,
    );
  }, skip: !Platform.isMacOS);

  testWidgets('report incident screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const ReportIncidentPage(), 'screen_report_incident.png');
  }, skip: !Platform.isMacOS);

  testWidgets('traffic screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const TrafficIncidentsPage(), 'screen_traffic.png');
  }, skip: !Platform.isMacOS);

  testWidgets('drive screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const RihlaDrivePage(), 'screen_drive.png', theme: AppTheme.dark);
  }, skip: !Platform.isMacOS);

  testWidgets('profile screen', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await golden(tester, const ProfilePage(), 'screen_profile.png', theme: AppTheme.dark);
  }, skip: !Platform.isMacOS);
}
