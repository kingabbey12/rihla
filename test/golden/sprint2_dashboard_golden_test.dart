import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/presentation/widgets/home_bottom_nav.dart';
import 'package:rihla/features/map/presentation/widgets/home_dashboard_overlay.dart';
import 'package:rihla/features/map/presentation/widgets/map_loading_view.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';

import '../features/home/home_dashboard_test_overrides.dart';

class _StubHome extends SearchHomeNotifier {
  @override
  Future<SearchPlace?> build() async => const SearchPlace(
        id: 'home',
        name: 'Home',
        address: 'Jumeirah, Dubai',
        latitude: 25.21,
        longitude: 55.27,
      );
}

class _StubWork extends SearchWorkNotifier {
  @override
  Future<SearchPlace?> build() async => const SearchPlace(
        id: 'work',
        name: 'Work',
        address: 'DIFC, Dubai',
        latitude: 25.21,
        longitude: 55.28,
      );
}

class _StubFavorites extends SearchFavoritesNotifier {
  @override
  Future<List<SearchPlace>> build() async => const [
        SearchPlace(
          id: 'fav1',
          name: 'Dubai Mall',
          address: 'Downtown Dubai',
          latitude: 25.197,
          longitude: 55.279,
        ),
      ];
}

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

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    required ThemeData theme,
    required Locale locale,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHomeProvider.overrideWith(_StubHome.new),
          searchWorkProvider.overrideWith(_StubWork.new),
          searchFavoritesProvider.overrideWith(_StubFavorites.new),
          ...homeDashboardTestOverrides(),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: _MapBackdrop()),
                HomeDashboardOverlay(),
                Positioned(left: 0, right: 0, bottom: 0, child: HomeBottomNav()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Sprint 2 dashboard — light, dark, Arabic RTL', (tester) async {
    await tester.runAsync(_loadRealFonts);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDashboard(tester, theme: AppTheme.light, locale: const Locale('en'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sprint2_dashboard_light.png'),
    );

    await pumpDashboard(tester, theme: AppTheme.dark, locale: const Locale('en'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sprint2_dashboard_dark.png'),
    );

    await pumpDashboard(tester, theme: AppTheme.light, locale: const Locale('ar'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sprint2_dashboard_arabic.png'),
    );
  }, skip: !Platform.isMacOS);

  testWidgets('Sprint 2 map loading shimmer', (tester) async {
    await tester.runAsync(_loadRealFonts);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MapLoadingView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sprint2_map_loading.png'),
    );
  }, skip: !Platform.isMacOS);
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(painter: _MapPainter(dark: isDark));
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = dark ? const Color(0xFF1A2230) : const Color(0xFFE9EDF2);
    canvas.drawRect(Offset.zero & size, bg);

    final park = Paint()
      ..color = dark ? const Color(0xFF243524) : const Color(0xFFD7E8CF);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 90, park);

    final water = Paint()
      ..color = dark ? const Color(0xFF1E3346) : const Color(0xFFBFD9EE);
    final waterPath = Path()
      ..moveTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.55,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..close();
    canvas.drawPath(waterPath, water);

    final roadColor = dark ? const Color(0xFF36404F) : Colors.white;
    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.5),
          Offset(size.width, size.height * 0.42), road)
      ..drawLine(Offset(size.width * 0.35, 0),
          Offset(size.width * 0.5, size.height), road)
      ..drawLine(Offset(0, size.height * 0.72),
          Offset(size.width, size.height * 0.8), road);

    canvas
      ..drawCircle(Offset(size.width * 0.5, size.height * 0.52), 16,
          Paint()..color = const Color(0x332E6BFF))
      ..drawCircle(Offset(size.width * 0.5, size.height * 0.52), 7,
          Paint()..color = const Color(0xFF2E6BFF));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
