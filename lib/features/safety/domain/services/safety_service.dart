import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';

/// Evaluates safety for an active navigation session.
abstract class SafetyService {
  Future<SafetySnapshot> evaluate(NavigationSession session, {int tickCount});
}
