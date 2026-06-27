import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

/// Contract for building journey previews from origin + destination.
abstract class JourneyPlanningService {
  Future<JourneySummary> planJourney({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
  });
}
