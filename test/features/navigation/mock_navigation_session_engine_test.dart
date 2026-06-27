import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'navigation_test_helpers.dart';

void main() {
  late MockNavigationSessionEngine engine;

  setUp(() {
    engine = MockNavigationSessionEngine();
  });

  test('createInitial seeds session from journey and route', () {
    final journey = sampleJourneySummary();
    final route = sampleRouteSummary();
    final session = engine.createInitial(
      sessionId: 'nav_test',
      journey: journey,
      route: route,
    );

    expect(session.sessionId, 'nav_test');
    expect(session.journey.destination.name, 'Kingdom Centre');
    expect(session.route.id, route.id);
    expect(session.status, NavigationStatus.navigating);
    expect(session.remainingDistanceKm, route.distanceKm);
    expect(session.simulationMode, isTrue);
    expect(session.currentManeuver.isPlaceholder, isTrue);
  });

  test('advance updates position and remaining distance', () {
    final journey = sampleJourneySummary();
    final route = sampleRouteSummary();
    final initial = engine.createInitial(
      sessionId: 'nav_test',
      journey: journey,
      route: route,
    );
    final updated = engine.advance(session: initial, tickCount: 2);

    expect(updated.remainingDistanceKm, lessThan(initial.remainingDistanceKm));
    expect(updated.speedKmh, greaterThan(0));
    expect(updated.routeProgressPercent, greaterThan(0));
    expect(updated.currentPosition.latitude, isNonZero);
  });
}
