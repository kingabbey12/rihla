import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';

/// System and user prompts assembled for the LLM.
class PromptPackage {
  const PromptPackage({
    required this.mode,
    required this.systemPrompt,
    required this.userPrompt,
    this.toolOutputs = const [],
  });

  final AiCopilotMode mode;
  final String systemPrompt;
  final String userPrompt;
  final List<String> toolOutputs;
}
