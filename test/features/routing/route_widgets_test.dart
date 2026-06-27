import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/presentation/widgets/route_loading_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_option_card.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

RouteSummary _sampleRoute(RouteProfile profile) => RouteSummary(
      id: 'mock_${profile.name}',
      profile: profile,
      distanceKm: 12.5,
      durationSeconds: 1320,
      coordinates: const [
        RouteCoordinate(latitude: 24.71, longitude: 46.67),
      ],
      journeyScore: 82,
      fuelEstimateLiters: 1.1,
      trafficSummary: 'Light traffic',
      safetySummary: 'High safety rating',
    );

void main() {
  testWidgets('RouteOptionCard shows profile and metrics', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RouteOptionCard(
          route: _sampleRoute(RouteProfile.fast),
          selected: true,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Fast'), findsOneWidget);
    expect(find.textContaining('12.5'), findsOneWidget);
  });

  testWidgets('RouteLoadingOverlay shows spinner', (tester) async {
    await tester.pumpWidget(_wrap(const RouteLoadingOverlay()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
