import 'package:rihla/features/ai_copilot/domain/entities/ai_message_role.dart';

/// A single turn in an AI conversation.
class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolName,
    this.toolOutputId,
  });

  final AiMessageRole role;
  final String content;
  final DateTime timestamp;
  final String? toolName;
  final String? toolOutputId;

  factory AiMessage.system(String content) => AiMessage(
        role: AiMessageRole.system,
        content: content,
        timestamp: DateTime.now(),
      );

  factory AiMessage.user(String content) => AiMessage(
        role: AiMessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory AiMessage.assistant(String content) => AiMessage(
        role: AiMessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

  factory AiMessage.tool({
    required String name,
    required String content,
    required String outputId,
  }) =>
      AiMessage(
        role: AiMessageRole.tool,
        content: content,
        timestamp: DateTime.now(),
        toolName: name,
        toolOutputId: outputId,
      );
}
