import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/presentation/pages/ai_conversation_page.dart';
import 'package:rihla/features/ai_copilot/presentation/pages/ai_home_page.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_driving_copilot_panel.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_advisor_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_review_body.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_voice_overlay.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 7 product verification on the real macOS Flutter runner.
///
/// Captures PNGs (not goldens) of the premium AI copilot experience:
/// AI Home, Conversation, Journey Advisor, Driving Copilot, Journey Review,
/// and Voice Mode — in light + dark.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 7 AI copilot screenshots', (tester) async {
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
    final out = Directory('${docs.path}/sprint7_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint7_capture_root')),
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
    final home = ValueNotifier<Widget>(const SizedBox.shrink());
    addTearDown(themeMode.dispose);
    addTearDown(home.dispose);

    Widget app() => UncontrolledProviderScope(
          container: container,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => ValueListenableBuilder<Widget>(
              valueListenable: home,
              builder: (context, child, _) => RepaintBoundary(
                key: const ValueKey('sprint7_capture_root'),
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
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
    }

    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 600));

    // —— Light pass ——
    await show(const AiHomePage());
    await capture('01_ai_home_light');

    await show(const AiConversationPage(initialPrompt: 'How is traffic?'));
    await tester.pump(const Duration(milliseconds: 1600));
    await capture('02_conversation_light');

    await show(_AdvisorHost(response: _sampleAdvisor()));
    await capture('03_journey_advisor_light');

    await show(_CopilotHost(response: _sampleCopilot()));
    await capture('04_driving_copilot_light');

    await show(_ReviewHost(response: _sampleReview()));
    await capture('05_journey_review_light');

    await show(const _VoiceHost());
    await capture('06_voice_light');

    // —— Dark pass ——
    themeMode.value = ThemeMode.dark;
    await tester.pump(const Duration(milliseconds: 400));

    await show(const AiHomePage());
    await capture('07_ai_home_dark');

    await show(const AiConversationPage(initialPrompt: 'Find me coffee nearby'));
    await tester.pump(const Duration(milliseconds: 1600));
    await capture('08_conversation_dark');

    await show(_AdvisorHost(response: _sampleAdvisor()));
    await capture('09_journey_advisor_dark');

    await show(_CopilotHost(response: _sampleCopilot()));
    await capture('10_driving_copilot_dark');

    await show(_ReviewHost(response: _sampleReview()));
    await capture('11_journey_review_dark');

    await show(const _VoiceHost());
    await capture('12_voice_dark');

    // Settle to a stable blank tree so pages dispose cleanly before teardown.
    home.value = const SizedBox.shrink();
    await tester.pump(const Duration(milliseconds: 600));

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

AiResponse _sampleAdvisor() => AiResponse(
      summary: 'Your trip to **Dubai Marina** looks great — light traffic and '
          'clear skies. Leaving soon keeps you ahead of the evening rush.',
      highlights: const [
        'Leave within 15 minutes for the smoothest flow',
        'Fast route balances time and fuel (~0.6 L)',
        'Weather is clear with good visibility',
      ],
      recommendations: const [
        AiRecommendation(
          id: 'r1',
          type: AiRecommendationType.departure,
          title: 'Recommended departure',
          body: 'Depart in the next 15 minutes for the smoothest flow.',
          priority: 5,
          actionable: true,
        ),
        AiRecommendation(
          id: 'r2',
          type: AiRecommendationType.traffic,
          title: 'Traffic outlook',
          body: 'Light congestion along Sheikh Zayed Rd right now.',
          priority: 4,
        ),
        AiRecommendation(
          id: 'r3',
          type: AiRecommendationType.weather,
          title: 'Weather',
          body: 'Clear skies — no rain expected on your route.',
          priority: 3,
        ),
      ],
      generatedAt: DateTime(2026, 6, 29, 8),
    );

AiResponse _sampleCopilot() => AiResponse(
      summary: 'Driving on **Sheikh Zayed Rd**. Safety score 88. No critical '
          'hazards ahead — maintain a safe following distance.',
      highlights: const [],
      recommendations: const [
        AiRecommendation(
          id: 'c1',
          type: AiRecommendationType.safety,
          title: 'Safety alert',
          body: 'Conditions are stable — keep both hands on the wheel.',
          priority: 5,
        ),
        AiRecommendation(
          id: 'c2',
          type: AiRecommendationType.reroute,
          title: 'Traffic update',
          body: 'Slowdown ahead — rerouting could save 6 minutes.',
          priority: 4,
          actionable: true,
        ),
      ],
      generatedAt: DateTime(2026, 6, 29, 8),
    );

AiResponse _sampleReview() => AiResponse(
      summary: 'Journey complete in 24 min over 18.5 km. A calm, efficient '
          'drive with strong awareness throughout.',
      highlights: const [
        'Safety trend was improving throughout the trip',
        'Smooth braking on the highway segment',
      ],
      recommendations: const [
        AiRecommendation(
          id: 'i1',
          type: AiRecommendationType.improvement,
          title: 'Smooth acceleration',
          body: 'Gentler starts can improve fuel efficiency next time.',
          priority: 4,
        ),
        AiRecommendation(
          id: 'i2',
          type: AiRecommendationType.driving,
          title: 'Driver score',
          body: 'Score 85 — strong overall awareness.',
          priority: 3,
        ),
      ],
      generatedAt: DateTime(2026, 6, 29, 8),
    );

class _AdvisorHost extends StatelessWidget {
  const _AdvisorHost({required this.response});

  final AiResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        title: const Text('Journey Advisor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AiJourneyAdvisorContent(
          response: response,
          streamSummary: false,
        ),
      ),
    );
  }
}

class _CopilotHost extends StatelessWidget {
  const _CopilotHost({required this.response});

  final AiResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        title: const Text('Driving Copilot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AiDrivingCopilotContent(
          response: response,
          onClose: () {},
          onQuickAction: (_) {},
          maxHeightFactor: 0.7,
          streamSummary: false,
        ),
      ),
    );
  }
}

class _ReviewHost extends StatelessWidget {
  const _ReviewHost({required this.response});

  final AiResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: AiJourneyReviewBody(
          summary: response.summary,
          highlights: response.highlights,
          recommendations: response.recommendations,
          journeyScore: 88,
          safetyScore: 92,
          drivingScore: 85,
          distanceKm: 18.5,
          durationMinutes: 24,
          fuelLiters: 1.5,
          streamSummary: false,
          onShare: () {},
          onSave: () {},
          onDone: () {},
        ),
      ),
    );
  }
}

class _VoiceHost extends StatelessWidget {
  const _VoiceHost();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          AiVoiceOverlay(
            phase: AiVoicePhase.listening,
            transcript: '"Find the fastest route home"',
            onClose: () {},
          ),
        ],
      ),
    );
  }
}
