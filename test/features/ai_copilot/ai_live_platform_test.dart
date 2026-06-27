import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_builder_impl.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_enricher.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_ai_service.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/openai_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/prompt_builder_impl.dart';
import 'package:rihla/features/ai_copilot/data/utils/ai_context_cache.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/errors/ai_failure.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

void main() {
  group('PromptBuilder', () {
    test('includes safety rules and structured context', () {
      final builder = PromptBuilderImpl();
      final package = builder.build(
        AiContext(
          mode: AiCopilotMode.journeyAdvisor,
          journey: _sampleJourney(),
          vehicleProfileSummary: const {'make': 'Toyota'},
        ),
      );

      expect(package.systemPrompt, contains('SAFETY RULES'));
      expect(package.systemPrompt, contains('Never override navigation'));
      expect(package.userPrompt, contains('[vehicle_profile]'));
      expect(package.userPrompt, contains('make: Toyota'));
    });

    test('includes medical profile only when flag set', () {
      final builder = PromptBuilderImpl();
      final withMedical = builder.build(
        AiContext(
          mode: AiCopilotMode.drivingCopilot,
          includeMedicalProfile: true,
          medicalProfileSummary: const {'blood_type': 'O+'},
        ),
      );
      final withoutMedical = builder.build(
        const AiContext(mode: AiCopilotMode.drivingCopilot),
      );

      expect(withMedical.userPrompt, contains('[medical_profile]'));
      expect(withoutMedical.userPrompt, isNot(contains('[medical_profile]')));
    });
  });

  group('ContextBuilder', () {
    test('builds advisor context from journey summary', () {
      final context = AiContextBuilderImpl().buildJourneyAdvisor(
        journey: _sampleJourney(),
      );
      expect(context.mode, AiCopilotMode.journeyAdvisor);
      expect(context.journey?.destination.name, 'Kingdom Centre');
    });
  });

  group('Context enricher', () {
    test('enriches with offline state and vehicle profile', () async {
      final enricher = AiContextEnricher(
        emergencyRepository: _FakeEmergencyRepo(),
        exploreRepository: _FakeExploreRepo(),
        isOffline: () => true,
      );
      final enriched = await enricher.enrich(
        const AiContext(mode: AiCopilotMode.journeyAdvisor),
      );
      expect(enriched.isOffline, isTrue);
      expect(enriched.vehicleProfileSummary['make'], 'Toyota');
    });
  });

  group('Context cache', () {
    test('reuses cached context by key', () {
      final cache = AiContextCache();
      const context = AiContext(
        mode: AiCopilotMode.journeyAdvisor,
        journey: null,
      );
      cache.put(context);
      expect(cache.get(context.cacheKey), isNotNull);
    });
  });

  group('OpenAI provider', () {
    test('disabled without API key', () {
      final provider = OpenAiLlmProvider(apiKey: null);
      expect(provider.isEnabled, isFalse);
      expect(
        () => provider.complete(_sampleRequest()),
        throwsA(isA<AiProviderDisabledFailure>()),
      );
    });

    test('enabled with API key', () {
      final provider = OpenAiLlmProvider(apiKey: 'test-key');
      expect(provider.isEnabled, isTrue);
    });
  });

  group('Mock LLM streaming', () {
    test('streams chunks and supports cancellation', () async {
      final provider = MockLlmProvider(simulatedDelay: Duration.zero);
      final stream = provider.stream(_sampleRequest());
      final chunks = <String>[];
      await for (final chunk in stream) {
        chunks.add(chunk);
        provider.cancel();
        break;
      }
      expect(chunks, isNotEmpty);
    });
  });

  group('Offline behavior', () {
    test('controller sets offline state when offline', () async {
      final container = ProviderContainer(
        overrides: [
          isOfflineModeProvider.overrideWith((ref) => true),
          llmProviderProvider.overrideWith(
            (ref) => MockLlmProvider(simulatedDelay: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiControllerProvider.notifier)
          .loadJourneyAdvisor(_sampleJourney());

      expect(container.read(aiControllerProvider), isA<AiCopilotOffline>());
    });
  });

  group('Conversation memory', () {
    test('service parses completion with conversation history', () async {
      final service = MockAiService(
        promptBuilder: PromptBuilderImpl(),
        llmProvider: MockLlmProvider(simulatedDelay: Duration.zero),
      );
      final response = await service.adviseJourney(
        AiContext(mode: AiCopilotMode.journeyAdvisor, journey: _sampleJourney()),
        conversation: AiConversation(
          id: 'c1',
          mode: AiCopilotMode.journeyAdvisor,
          messages: [AiMessage.user('prior question')],
        ),
      );
      expect(response.summary, isNotEmpty);
      expect(response.recommendations, isNotEmpty);
    });
  });

  group('Safety rules', () {
    test('prompt forbids automatic emergency actions', () {
      final package = PromptBuilderImpl().build(
        AiContext(mode: AiCopilotMode.drivingCopilot, journey: _sampleJourney()),
      );
      expect(package.systemPrompt, contains('contact emergency services'));
      expect(package.systemPrompt, contains('advisory only'));
    });
  });
}

LlmRequest _sampleRequest() => LlmRequest(
      mode: AiCopilotMode.journeyAdvisor,
      systemPrompt: 'test',
      messages: [AiMessage.user('hello')],
    );

JourneySummary _sampleJourney() {
  const components = JourneyScoreComponents(
    safety: 85,
    traffic: 72,
    weather: 90,
    roadConditions: 78,
    fuelEfficiency: 80,
    vehicleStatus: 92,
  );
  return JourneySummary(
    destination: const JourneyEndpoint(
      id: 'dest',
      name: 'Kingdom Centre',
      address: 'King Fahd Road',
      latitude: 24.71,
      longitude: 46.67,
    ),
    origin: const JourneyEndpoint(
      id: 'origin',
      name: 'Current Location',
      address: 'Riyadh',
      latitude: 24.7136,
      longitude: 46.6753,
    ),
    metrics: const JourneyMetrics(
      distanceKm: 8.5,
      durationMinutes: 18,
      weatherSummary: 'Clear skies',
      temperatureCelsius: 32,
      trafficLevel: TrafficLevel.moderate,
      fuelEstimateLiters: 0.6,
      batteryEstimatePercent: 10,
      roadCondition: RoadConditionLevel.good,
      departureSuggestions: ['Leave now'],
    ),
    score: JourneyScore(
      journeyScore: 82,
      safetyScore: 84,
      components: components,
    ),
    aiSummary: const AiJourneySummary(
      headline: 'Test',
      body: 'Body',
      highlights: ['A'],
    ),
  );
}

class _FakeEmergencyRepo implements EmergencyRepository {
  @override
  Future<MedicalProfile> getMedicalProfile() async => MedicalProfile.empty;

  @override
  Future<EmergencyVehicleProfile> getVehicleProfile() async =>
      const EmergencyVehicleProfile(make: 'Toyota', model: 'Camry');

  @override
  EmergencyTimeline? getActiveTimeline() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExploreRepo implements ExploreRepository {
  @override
  Future<List<ExploreJourneyRecommendation>> getJourneyRecommendations({
    required double latitude,
    required double longitude,
    double? remainingFuelPercent,
    double? remainingBatteryPercent,
    int? journeyDurationMinutes,
    bool trafficHeavy = false,
    bool weatherAdverse = false,
  }) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
