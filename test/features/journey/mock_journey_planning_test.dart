import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';

void main() {
  const origin = JourneyEndpoint(
    name: 'Origin',
    address: 'Riyadh',
    latitude: 24.7136,
    longitude: 46.6753,
  );
  const destination = JourneyEndpoint(
    id: 'kingdom_centre',
    name: 'Kingdom Centre',
    address: 'King Fahd Road',
    latitude: 24.7113,
    longitude: 46.6743,
  );

  late MockJourneyPlanningService service;

  setUp(() {
    service = MockJourneyPlanningService(
      MockAiRecommendationService(),
      simulatedDelay: Duration.zero,
    );
  });

  test('plans journey with metrics and scores', () async {
    final summary = await service.planJourney(
      origin: origin,
      destination: destination,
    );

    expect(summary.destination.name, 'Kingdom Centre');
    expect(summary.metrics.distanceKm, greaterThan(0));
    expect(summary.metrics.durationMinutes, greaterThan(0));
    expect(summary.score.journeyScore, inInclusiveRange(0, 100));
    expect(summary.score.safetyScore, inInclusiveRange(0, 100));
    expect(summary.aiSummary.headline, isNotEmpty);
    expect(summary.metrics.departureSuggestions, isNotEmpty);
  });

  test('same destination produces consistent scores', () async {
    final a = await service.planJourney(origin: origin, destination: destination);
    final b = await service.planJourney(origin: origin, destination: destination);
    expect(a.score.journeyScore, b.score.journeyScore);
  });
}
