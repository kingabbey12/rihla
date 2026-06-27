import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/data/repositories/ai_repository_impl.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';

void main() {
  test('save and retrieve conversation', () async {
    final repo = AiRepositoryImpl();
    final conversation = AiConversation(
      id: 'ai_1',
      mode: AiCopilotMode.journeyAdvisor,
      messages: const [],
    );
    await repo.save(conversation);
    expect(repo.current?.id, 'ai_1');
    await repo.clear();
    expect(repo.current, isNull);
  });
}
