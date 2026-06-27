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
}
