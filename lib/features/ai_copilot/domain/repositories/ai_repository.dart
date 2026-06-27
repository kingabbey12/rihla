import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';

/// Persists AI conversations and responses.
abstract class AiRepository {
  AiConversation? get current;

  Future<void> save(AiConversation conversation);

  Future<void> clear();
}
