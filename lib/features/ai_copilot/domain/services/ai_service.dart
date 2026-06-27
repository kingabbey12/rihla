import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';

/// AI advisory service — consumes structured context, produces recommendations.
abstract class AiService {
  Future<AiResponse> adviseJourney(
    AiContext context, {
    AiConversation? conversation,
  });

  Future<AiResponse> copilotUpdate(
    AiContext context, {
    AiConversation? conversation,
  });

  Future<AiResponse> reviewJourney(
    AiContext context, {
    AiConversation? conversation,
  });
}
