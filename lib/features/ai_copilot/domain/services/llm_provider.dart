import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';

/// Request sent to an LLM provider.
class LlmRequest {
  const LlmRequest({
    required this.mode,
    required this.systemPrompt,
    required this.messages,
    this.temperature = 0.4,
  });

  final AiCopilotMode mode;
  final String systemPrompt;
  final List<AiMessage> messages;
  final double temperature;
}

/// Raw completion from an LLM provider.
class LlmCompletion {
  const LlmCompletion({
    required this.text,
    this.fromMock = true,
  });

  final String text;
  final bool fromMock;
}

/// Abstraction over LLM backends (mock, OpenAI, etc.).
abstract class LLMProvider {
  bool get isEnabled;

  Future<LlmCompletion> complete(LlmRequest request);
}
