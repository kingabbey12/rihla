import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Controller state for the safety subsystem.
sealed class SafetyState {
  const SafetyState();
}

/// No active safety evaluation (no navigation session).
final class SafetyInactive extends SafetyState {
  const SafetyInactive();
}

/// Safety is active and tied to a navigation session.
final class SafetyActive extends SafetyState {
  const SafetyActive(this.snapshot);

  final SafetySnapshot snapshot;
}
