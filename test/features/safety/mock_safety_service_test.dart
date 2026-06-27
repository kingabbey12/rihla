import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  test('evaluate returns assessment and hazards', () async {
    final engine = MockNavigationSessionEngine();
    final service = MockSafetyService();
    final session = engine.createInitial(
      sessionId: 'nav_1',
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );

    final snapshot = await service.evaluate(session, tickCount: 3);

    expect(snapshot.assessment.overallSafetyScore, greaterThan(0));
    expect(snapshot.hazards, isNotEmpty);
    expect(snapshot.primaryAlert, isNotNull);
  });

  test('higher tick adds construction hazard', () async {
    final engine = MockNavigationSessionEngine();
    final service = MockSafetyService();
    final session = engine.createInitial(
      sessionId: 'nav_1',
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );

    final early = await service.evaluate(session, tickCount: 0);
    final later = await service.evaluate(session, tickCount: 4);

    expect(later.hazards.length, greaterThan(early.hazards.length));
    expect(
      later.hazards.any((h) => h.type == HazardType.construction),
      isTrue,
    );
  });
}
