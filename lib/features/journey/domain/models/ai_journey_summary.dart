/// AI-generated journey insight (mock for now).
class AiJourneySummary {
  const AiJourneySummary({
    required this.headline,
    required this.body,
    this.highlights = const [],
  });

  final String headline;
  final String body;
  final List<String> highlights;
}
