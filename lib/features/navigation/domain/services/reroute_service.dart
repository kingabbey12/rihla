import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Recalculates a route after deviation.
abstract class RerouteService {
  Future<RouteSummary> recalculate({
    required JourneySummary journey,
    required RouteSummary currentRoute,
  });
}
