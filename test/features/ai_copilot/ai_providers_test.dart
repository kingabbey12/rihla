import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/data/services/ai_context_enricher.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_llm_provider.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  test('loadJourneyAdvisor transitions to advisor ready', () async {
    final container = ProviderContainer(
      overrides: [
        isOfflineModeProvider.overrideWith((ref) => false),
        aiContextEnricherProvider.overrideWith(
          (ref) => AiContextEnricher(
            emergencyRepository: _TestEmergencyRepo(),
            exploreRepository: _TestExploreRepo(),
            isOffline: () => false,
          ),
        ),
        llmProviderProvider.overrideWith(
          (ref) => MockLlmProvider(simulatedDelay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(aiControllerProvider.notifier)
        .loadJourneyAdvisor(sampleJourneySummary());

    expect(container.read(aiControllerProvider), isA<AiCopilotAdvisorReady>());
    expect(container.read(aiRecommendationsProvider), isNotEmpty);
  });

  test('mock llm provider is enabled', () {
    final provider = MockLlmProvider(simulatedDelay: Duration.zero);
    expect(provider.isEnabled, isTrue);
  });

  test('mock llm completes advisor request', () async {
    final provider = MockLlmProvider(simulatedDelay: Duration.zero);
    final completion = await provider.complete(
      LlmRequest(
        mode: AiCopilotMode.journeyAdvisor,
        systemPrompt: 'test',
        messages: [
          AiMessage.user('destination: Test\njourney_score: 80'),
        ],
      ),
    );
    expect(completion.text, contains('SUMMARY:'));
  });
}

class _TestEmergencyRepo implements EmergencyRepository {
  @override
  Future<MedicalProfile> getMedicalProfile() async => MedicalProfile.empty;

  @override
  Future<EmergencyVehicleProfile> getVehicleProfile() async =>
      EmergencyVehicleProfile.empty;

  @override
  EmergencyTimeline? getActiveTimeline() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestExploreRepo implements ExploreRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
