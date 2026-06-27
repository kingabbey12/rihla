import 'package:rihla/features/ai_copilot/domain/entities/ai_conversation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';

/// Central AI copilot state.
sealed class AiCopilotState {
  const AiCopilotState();
}

final class AiCopilotInactive extends AiCopilotState {
  const AiCopilotInactive();
}

final class AiCopilotLoading extends AiCopilotState {
  const AiCopilotLoading(this.mode);

  final AiCopilotMode mode;
}

final class AiCopilotAdvisorReady extends AiCopilotState {
  const AiCopilotAdvisorReady({
    required this.response,
    required this.conversation,
  });

  final AiResponse response;
  final AiConversation conversation;
}

final class AiCopilotDrivingReady extends AiCopilotState {
  const AiCopilotDrivingReady({
    required this.response,
    required this.conversation,
  });

  final AiResponse response;
  final AiConversation conversation;
}

final class AiCopilotReviewReady extends AiCopilotState {
  const AiCopilotReviewReady({
    required this.response,
    required this.conversation,
  });

  final AiResponse response;
  final AiConversation conversation;
}

final class AiCopilotError extends AiCopilotState {
  const AiCopilotError(this.message);

  final String message;
}
