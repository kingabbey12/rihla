import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

/// High-level journey operations.
abstract class JourneyRepository {
  Future<JourneySummary> planJourney({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
  });
}
