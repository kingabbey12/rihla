/// AI copilot failures.
sealed class AiFailure {
  const AiFailure(this.message);

  final String message;
}

final class AiProviderDisabledFailure extends AiFailure {
  const AiProviderDisabledFailure()
      : super('AI provider is disabled. Add an API key to enable OpenAI.');
}

final class AiGenerationFailure extends AiFailure {
  const AiGenerationFailure(super.message);
}
