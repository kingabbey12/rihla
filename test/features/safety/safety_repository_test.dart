import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

void main() {
  test('save and retrieve snapshot', () async {
    final repo = SafetyRepositoryImpl();
    final snapshot = SafetySnapshot.initial();
    await repo.save(snapshot);
    expect(repo.current?.assessment.overallSafetyScore, 80);
    await repo.clear();
    expect(repo.current, isNull);
  });
}
