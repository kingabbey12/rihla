import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';
import 'package:rihla/features/safety/domain/repositories/safety_repository.dart';

/// In-memory safety snapshot store.
class SafetyRepositoryImpl implements SafetyRepository {
  SafetySnapshot? _current;

  @override
  SafetySnapshot? get current => _current;

  @override
  Future<void> save(SafetySnapshot snapshot) async {
    _current = snapshot;
  }

  @override
  Future<void> clear() async {
    _current = null;
  }
}
