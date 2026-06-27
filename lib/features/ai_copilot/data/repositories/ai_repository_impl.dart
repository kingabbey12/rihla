import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/repositories/ai_repository.dart';

/// In-memory AI conversation store.
class AiRepositoryImpl implements AiRepository {
  AiConversation? _current;

  @override
  AiConversation? get current => _current;

  @override
  Future<void> save(AiConversation conversation) async {
    _current = conversation;
  }

  @override
  Future<void> clear() async {
    _current = null;
  }

  @override
  String exportConversation(AiConversation conversation) {
    final buffer = StringBuffer()
      ..writeln('# Rihla AI Conversation')
      ..writeln('mode: ${conversation.mode.name}')
      ..writeln('id: ${conversation.id}')
      ..writeln('---');
    for (final message in conversation.messages) {
      buffer.writeln('[${message.role.name}] ${message.timestamp.toIso8601String()}');
      buffer.writeln(message.content);
      buffer.writeln();
    }
    if (conversation.toolOutputs.isNotEmpty) {
      buffer.writeln('--- tool outputs ---');
      for (final tool in conversation.toolOutputs) {
        buffer.writeln(tool);
      }
    }
    if (conversation.memory.isNotEmpty) {
      buffer.writeln('--- memory ---');
      conversation.memory.forEach((k, v) => buffer.writeln('$k: $v'));
    }
    return buffer.toString();
  }
}
