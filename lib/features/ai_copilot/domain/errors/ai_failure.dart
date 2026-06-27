/// AI copilot failures.
sealed class AiFailure {
  const AiFailure(this.message);

  final String message;
}

final class AiProviderDisabledFailure extends AiFailure {
  const AiProviderDisabledFailure()
      : super('AI provider is disabled. Configure OPENAI_API_KEY to enable.');
}

final class AiOfflineFailure extends AiFailure {
  const AiOfflineFailure()
      : super('AI unavailable while offline.');
}

final class AiGenerationFailure extends AiFailure {
  const AiGenerationFailure(super.message);
}

final class AiTimeoutFailure extends AiFailure {
  const AiTimeoutFailure()
      : super('AI request timed out. Please try again.');
}

final class AiRateLimitFailure extends AiFailure {
  const AiRateLimitFailure()
      : super('AI rate limit reached. Please wait and try again.');
}

final class AiCancelledFailure extends AiFailure {
  const AiCancelledFailure()
      : super('AI request was cancelled.');
}
