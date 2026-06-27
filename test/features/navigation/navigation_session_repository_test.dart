import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/data/repositories/navigation_session_repository_impl.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';

import 'navigation_test_helpers.dart';

void main() {
  late NavigationSessionRepositoryImpl repository;

  setUp(() {
    repository = NavigationSessionRepositoryImpl();
  });

  test('starts with no current session', () {
    expect(repository.current, isNull);
  });

  test('save and retrieve session', () async {
    final session = MockNavigationSessionEngine().createInitial(
      sessionId: 'nav_1',
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    await repository.save(session);
    expect(repository.current?.sessionId, 'nav_1');
    expect(repository.current?.status, NavigationStatus.navigating);
  });

  test('clear removes session', () async {
    await repository.save(
      MockNavigationSessionEngine().createInitial(
        sessionId: 'nav_1',
        journey: sampleJourneySummary(),
        route: sampleRouteSummary(),
      ),
    );
    await repository.clear();
    expect(repository.current, isNull);
  });
}
