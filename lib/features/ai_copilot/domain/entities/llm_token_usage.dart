/// Token usage reported by an LLM completion.
class LlmTokenUsage {
  const LlmTokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  static const zero = LlmTokenUsage(
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
  );
}
