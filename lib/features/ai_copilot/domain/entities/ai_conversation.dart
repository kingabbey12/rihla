import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message.dart';

/// Conversation state for an AI experience.
class AiConversation {
  const AiConversation({
    required this.id,
    required this.mode,
    required this.messages,
    this.lastContext,
    this.toolOutputs = const [],
    this.memory = const {},
  });

  final String id;
  final AiCopilotMode mode;
  final List<AiMessage> messages;
  final AiContext? lastContext;

  /// Structured tool outputs (e.g. safety engine, route engine).
  final List<String> toolOutputs;

  /// Reserved for future persistent memory.
  final Map<String, String> memory;

  AiConversation copyWith({
    List<AiMessage>? messages,
    AiContext? lastContext,
    List<String>? toolOutputs,
    Map<String, String>? memory,
  }) {
    return AiConversation(
      id: id,
      mode: mode,
      messages: messages ?? this.messages,
      lastContext: lastContext ?? this.lastContext,
      toolOutputs: toolOutputs ?? this.toolOutputs,
      memory: memory ?? this.memory,
    );
  }

  AiConversation appendMessage(AiMessage message) =>
      copyWith(messages: [...messages, message]);
}
