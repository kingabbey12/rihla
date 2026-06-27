import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';
import 'package:rihla/features/ai_copilot/domain/entities/llm_token_usage.dart';

/// Request sent to an LLM provider.
class LlmRequest {
  const LlmRequest({
    required this.mode,
    required this.systemPrompt,
    required this.messages,
    this.temperature = 0.4,
    this.requestJson = false,
  });

  final AiCopilotMode mode;
  final String systemPrompt;
  final List<AiMessage> messages;
  final double temperature;

  /// When true, request JSON-object response format from the provider.
  final bool requestJson;
}

/// Raw completion from an LLM provider.
class LlmCompletion {
  const LlmCompletion({
    required this.text,
    this.fromMock = true,
    this.tokenUsage = LlmTokenUsage.zero,
  });

  final String text;
  final bool fromMock;
  final LlmTokenUsage tokenUsage;
}

/// Abstraction over LLM backends (mock, OpenAI, future proxy).
abstract class LLMProvider {
  bool get isEnabled;

  LlmTokenUsage? get lastTokenUsage;

  Future<LlmCompletion> complete(LlmRequest request);

  Stream<String> stream(LlmRequest request);

  void cancel();
}
