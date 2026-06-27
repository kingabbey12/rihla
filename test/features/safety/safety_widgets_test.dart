import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';
import 'package:rihla/features/safety/domain/entities/safety_assessment.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_alert_banner.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_dashboard.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Hazard _hazard() => Hazard(
      id: 'hz_1',
      type: HazardType.construction,
      severity: HazardSeverity.high,
      title: 'Road construction',
      description: 'Lane closure ahead',
      distanceAheadKm: 1.2,
      reportedAt: DateTime.now(),
    );

SafetyAssessment _assessment() => SafetyAssessment.neutral();

void main() {
  testWidgets('SafetyAlertBanner shows hazard title', (tester) async {
    await tester.pumpWidget(_wrap(SafetyAlertBanner(hazard: _hazard())));
    expect(find.text('Road construction'), findsOneWidget);
    expect(find.text('Safety Alert'), findsOneWidget);
  });

  testWidgets('SafetyDashboard shows score rings', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SafetyDashboard(
          assessment: _assessment(),
          hazards: [_hazard()],
          onClose: () {},
        ),
      ),
    );
    expect(find.text('Safety Intelligence'), findsOneWidget);
    expect(find.text('Hazard Feed'), findsOneWidget);
    expect(find.byType(SafetyDashboard), findsOneWidget);
  });
}
