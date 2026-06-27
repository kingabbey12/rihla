import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/domain/repositories/journey_repository.dart';
import 'package:rihla/features/journey/domain/services/journey_planning_service.dart';

class JourneyRepositoryImpl implements JourneyRepository {
  JourneyRepositoryImpl(this._planningService);

  final JourneyPlanningService _planningService;

  @override
  Future<JourneySummary> planJourney({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
  }) =>
      _planningService.planJourney(origin: origin, destination: destination);
}
