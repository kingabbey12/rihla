import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/presentation/widgets/map_controls.dart';
import 'package:rihla/features/map/presentation/widgets/map_debug_overlay.dart';
import 'package:rihla/features/map/presentation/widgets/map_empty_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_error_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_loading_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_scale_indicator.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child, {bool withScope = false}) {
  final app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
  return withScope ? ProviderScope(child: app) : app;
}

void main() {
  testWidgets('MapControls fires every callback', (tester) async {
    var zoomIn = 0, zoomOut = 0, recenter = 0, myLocation = 0;

    await tester.pumpWidget(
      _wrap(
        MapControls(
          onZoomIn: () => zoomIn++,
          onZoomOut: () => zoomOut++,
          onRecenter: () => recenter++,
          onMyLocation: () => myLocation++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.tap(find.byIcon(Icons.location_searching));
    await tester.pump();

    expect(zoomIn, 1);
    expect(zoomOut, 1);
    expect(recenter, 1);
    expect(myLocation, 1);
  });

  testWidgets('MapControls shows active my-location icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MapControls(
          onZoomIn: () {},
          onZoomOut: () {},
          onRecenter: () {},
          onMyLocation: () {},
          myLocationActive: true,
        ),
      ),
    );
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.location_searching), findsNothing);
  });

  testWidgets('MapScaleIndicator renders a label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MapScaleIndicator(
          camera: MapCamera(latitude: 24.7, longitude: 46.6, zoom: 12),
        ),
      ),
    );
    expect(find.byType(MapScaleIndicator), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('MapLoadingView shows a spinner', (tester) async {
    await tester.pumpWidget(_wrap(const MapLoadingView()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MapErrorView retry callback fires', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(MapErrorView(onRetry: () => retried++)));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('MapEmptyView retry and dismiss fire', (tester) async {
    var retried = 0, dismissed = 0;
    await tester.pumpWidget(
      _wrap(
        MapEmptyView(
          onRetry: () => retried++,
          onDismiss: () => dismissed++,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(retried, 1);
    expect(dismissed, 1);
  });

  testWidgets('MapDebugOverlay renders debug rows', (tester) async {
    await tester.pumpWidget(_wrap(const MapDebugOverlay(), withScope: true));
    expect(find.textContaining('FPS'), findsOneWidget);
    expect(find.textContaining('ZOOM'), findsOneWidget);
    expect(find.textContaining('STYLE'), findsOneWidget);
  });
}
