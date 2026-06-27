import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/models/prompt_package.dart';

/// Builds structured prompts from [AiContext].
abstract class PromptBuilder {
  PromptPackage build(AiContext context, {AiConversation? conversation});
}
