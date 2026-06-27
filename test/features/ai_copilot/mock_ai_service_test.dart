import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_ai_service.dart';
import 'package:rihla/features/ai_copilot/data/services/mock_llm_provider.dart';
import 'package:rihla/features/ai_copilot/data/services/prompt_builder_impl.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  late MockAiService service;

  setUp(() {
    service = MockAiService(
      promptBuilder: PromptBuilderImpl(),
      llmProvider: MockLlmProvider(simulatedDelay: Duration.zero),
    );
  });

  test('adviseJourney returns summary and recommendations', () async {
    final response = await service.adviseJourney(
      AiContext(
        mode: AiCopilotMode.journeyAdvisor,
        journey: sampleJourneySummary(),
      ),
    );

    expect(response.summary, isNotEmpty);
    expect(response.recommendations, isNotEmpty);
    expect(response.fromMock, isTrue);
  });

  test('copilotUpdate handles driving context', () async {
    final journey = sampleJourneySummary();
    final route = sampleRouteSummary();
    final response = await service.copilotUpdate(
      AiContext(
        mode: AiCopilotMode.drivingCopilot,
        journey: journey,
        route: route,
      ),
    );

    expect(response.highlights, isNotEmpty);
  });
}
