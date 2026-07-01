/// Aggregated journey insights for the home dashboard AI brief card.
class HomeJourneyBrief {
  const HomeJourneyBrief({
    required this.available,
    this.trafficSummary,
    this.weatherWarning,
    this.bestDeparture,
    this.roadIncidents,
    this.aiRecommendation,
  });

  const HomeJourneyBrief.unavailable()
      : available = false,
        trafficSummary = null,
        weatherWarning = null,
        bestDeparture = null,
        roadIncidents = null,
        aiRecommendation = null;

  final bool available;
  final String? trafficSummary;
  final String? weatherWarning;
  final String? bestDeparture;
  final String? roadIncidents;
  final String? aiRecommendation;
}
