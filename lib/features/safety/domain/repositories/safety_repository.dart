import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Persists and retrieves safety snapshots for the active session.
abstract class SafetyRepository {
  SafetySnapshot? get current;

  Future<void> save(SafetySnapshot snapshot);

  Future<void> clear();
}
