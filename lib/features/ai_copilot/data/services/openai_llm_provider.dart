import 'package:rihla/features/ai_copilot/domain/errors/ai_failure.dart';
import 'package:rihla/features/ai_copilot/domain/services/llm_provider.dart';

/// OpenAI adapter — disabled until API keys are configured.
///
/// Swap [llmProviderProvider] to this implementation when ready.
/// Do not integrate real API calls until explicitly approved.
class OpenAiLlmProvider implements LLMProvider {
  OpenAiLlmProvider({
    this.apiKey,
    this.model = 'gpt-4o-mini',
    this.baseUrl = 'https://api.openai.com/v1',
  });

  final String? apiKey;
  final String model;
  final String baseUrl;

  @override
  bool get isEnabled => apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<LlmCompletion> complete(LlmRequest request) async {
    if (!isEnabled) {
      throw const AiProviderDisabledFailure();
    }

    // Real HTTP integration deferred until API keys are approved.
    throw const AiGenerationFailure(
      'OpenAI adapter is configured but not yet integrated.',
    );
  }
}
