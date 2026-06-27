import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_turn_banner.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

import 'navigation_test_helpers.dart';

void main() {
  testWidgets('NavigationTurnBanner shows maneuver and road', (tester) async {
    final engine = MockNavigationSessionEngine(
      maneuverEngine: PolylineManeuverEngine(),
      deviationDetector: PolylineRouteDeviationDetector(),
    );
    final session = engine.createInitial(
      sessionId: 'nav_test',
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
      voiceEnabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NavigationTurnBanner(
            session: session,
            onToggleVoice: () {},
          ),
        ),
      ),
    );

    expect(find.text(session.currentRoad), findsOneWidget);
    expect(find.textContaining('Then'), findsOneWidget);
  });
}
