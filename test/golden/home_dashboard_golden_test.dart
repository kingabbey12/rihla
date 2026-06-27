import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/presentation/widgets/home_bottom_nav.dart';
import 'package:rihla/features/map/presentation/widgets/home_dashboard_overlay.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/map_search_bar.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';

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

/// Loads real glyphs so golden text/icons render as type instead of boxes.
/// Text uses the macOS Arial faces registered under `Roboto` (the family
/// Flutter falls back to in tests); icons use the Flutter SDK Material Icons
/// font resolved from the local SDK cache.
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
  testWidgets('AI Home Dashboard renders approved layout', (tester) async {
    await tester.runAsync(_loadRealFonts);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHomeProvider.overrideWith(_StubHome.new),
          searchWorkProvider.overrideWith(_StubWork.new),
          searchFavoritesProvider.overrideWith(_StubFavorites.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: _MapBackdrop()),
                MapSearchBar(),
                HomeDashboardOverlay(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: HomeBottomNav(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Allow saved-place futures and the entrance animation to settle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_dashboard.png'),
    );
  },
      // Golden pixels depend on the macOS system fonts used to generate the
      // reference image; skip elsewhere so cross-platform CI stays green.
      skip: !Platform.isMacOS);
}

/// Lightweight map-style backdrop so the golden conveys the full-screen map
/// without the native MapLibre surface (which cannot render in tests).
class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapPainter());
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE9EDF2);
    canvas.drawRect(Offset.zero & size, bg);

    final park = Paint()..color = const Color(0xFFD7E8CF);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 90, park);

    final water = Paint()..color = const Color(0xFFBFD9EE);
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

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.42), road)
      ..drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.5, size.height), road)
      ..drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.8), road);

    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.7, size.height), minor)
      ..drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.2), minor);

    // Current-location dot.
    canvas
      ..drawCircle(Offset(size.width * 0.5, size.height * 0.52), 16,
          Paint()..color = const Color(0x332E6BFF))
      ..drawCircle(Offset(size.width * 0.5, size.height * 0.52), 7,
          Paint()..color = const Color(0xFF2E6BFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
