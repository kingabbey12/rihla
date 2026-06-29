import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/presentation/pages/emergency_dashboard_page.dart';
import 'package:rihla/features/emergency/presentation/pages/report_incident_page.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_timeline_view.dart';
import 'package:rihla/features/emergency/presentation/widgets/medical_profile_card.dart';
import 'package:rihla/features/emergency/presentation/widgets/roadside_request_sheet.dart';
import 'package:rihla/features/emergency/presentation/widgets/vehicle_profile_card.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 6 product verification on the real macOS Flutter runner.
///
/// Captures PNGs of the premium Emergency experience (not goldens):
/// home, SOS countdown, roadside, incident wizard, and profiles, light + dark.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 6 emergency screenshots', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/sprint6_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint6_capture_root')),
      ) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File('${out.path}/$name.png').writeAsBytes(
          bytes.buffer.asUint8List(),
        );
      }
      image.dispose();
    }

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
    final home = ValueNotifier<Widget>(const EmergencyDashboardPage());
    addTearDown(themeMode.dispose);
    addTearDown(home.dispose);

    Widget app() => UncontrolledProviderScope(
          container: container,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => ValueListenableBuilder<Widget>(
              valueListenable: home,
              builder: (context, child, _) => RepaintBoundary(
                key: const ValueKey('sprint6_capture_root'),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  themeMode: mode,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: child,
                ),
              ),
            ),
          ),
        );

    Future<void> show(Widget widget) async {
      home.value = widget;
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Emergency Home (light)
    await show(const EmergencyDashboardPage());
    await capture('01_emergency_home_light');

    // 2. SOS Countdown (light) — trigger countdown on the live dashboard.
    container.read(emergencyControllerProvider.notifier).startSosCountdown();
    await tester.pump(const Duration(milliseconds: 500));
    await capture('02_sos_countdown_light');
    container.read(emergencyControllerProvider.notifier).cancelSos();
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Roadside Assistance (light)
    await show(const _SheetHost(child: RoadsideRequestSheet()));
    await capture('03_roadside_light');

    // 4. Incident Report wizard (light)
    await show(const ReportIncidentPage());
    await capture('04_incident_report_light');

    // 5. Medical + Vehicle profiles (light)
    await show(_ProfilesHost(timeline: _sampleTimeline()));
    await capture('05_profiles_light');

    // —— Dark mode pass ——
    themeMode.value = ThemeMode.dark;
    await tester.pump(const Duration(milliseconds: 400));

    await show(const EmergencyDashboardPage());
    await capture('06_emergency_home_dark');

    await show(const _SheetHost(child: RoadsideRequestSheet()));
    await capture('07_roadside_dark');

    await show(const ReportIncidentPage());
    await capture('08_incident_report_dark');

    await show(_ProfilesHost(timeline: _sampleTimeline()));
    await capture('09_profiles_dark');

    // Settle to a stable blank tree so pages dispose cleanly before teardown.
    home.value = const SizedBox.shrink();
    await tester.pump(const Duration(milliseconds: 400));

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

EmergencyTimeline _sampleTimeline() => EmergencyTimeline(
      id: 'sample',
      events: [
        EmergencyTimelineEvent(
          id: '1',
          type: EmergencyTimelineEventType.sosSent,
          timestamp: DateTime(2026, 6, 29, 8, 12),
          description: 'SOS triggered from your device',
        ),
        EmergencyTimelineEvent(
          id: '2',
          type: EmergencyTimelineEventType.locationShared,
          timestamp: DateTime(2026, 6, 29, 8, 12),
          description: 'Live location captured and shared',
        ),
        EmergencyTimelineEvent(
          id: '3',
          type: EmergencyTimelineEventType.assistanceRequested,
          timestamp: DateTime(2026, 6, 29, 8, 14),
          description: 'Roadside assistance dispatched',
        ),
      ],
    );

const _sampleMedical = MedicalProfile(
  bloodType: 'O+',
  allergies: ['Penicillin', 'Peanuts'],
  medicalConditions: ['Asthma'],
  emergencyMedications: ['Ventolin'],
  emergencyNotes: 'Type 1 diabetic',
);

const _sampleVehicle = EmergencyVehicleProfile(
  make: 'Toyota',
  model: 'Land Cruiser',
  year: 2022,
  licensePlate: 'Dubai A 12345',
  insuranceProvider: 'AXA Gulf',
  roadsideMembership: 'AAA Gold',
  fuelType: 'Petrol',
  color: 'White',
);

class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfilesHost extends StatelessWidget {
  const _ProfilesHost({required this.timeline});

  final EmergencyTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        title: const Text('Emergency profiles'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MedicalProfileCard(profile: _sampleMedical, onEdit: () {}),
          const SizedBox(height: 12),
          VehicleProfileCard(profile: _sampleVehicle, onEdit: () {}),
          const SizedBox(height: 20),
          EmergencyTimelineView(timeline: timeline),
        ],
      ),
    );
  }
}
