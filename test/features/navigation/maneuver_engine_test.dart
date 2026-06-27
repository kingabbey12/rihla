import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';

import 'navigation_test_helpers.dart';

void main() {
  late PolylineManeuverEngine engine;

  setUp(() {
    engine = PolylineManeuverEngine();
  });

  test('buildSteps includes continue, maneuvers, and arrive', () {
    final steps = engine.buildSteps(sampleRouteSummary());

    expect(steps, isNotEmpty);
    expect(steps.first.type, ManeuverType.continueStraight);
    expect(steps.last.type, ManeuverType.arrive);
    expect(steps.length, greaterThan(2));
  });

  test('instructionFor returns readable text', () {
    expect(
      engine.instructionFor(ManeuverType.turnRight, 'Olaya St'),
      contains('Olaya St'),
    );
    expect(
      engine.instructionFor(ManeuverType.arrive, 'Destination'),
      contains('arrived'),
    );
  });

  test('supports all required maneuver types', () {
    for (final type in ManeuverType.values) {
      expect(engine.instructionFor(type, 'Test Rd'), isNotEmpty);
    }
  });
}
