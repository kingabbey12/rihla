import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';

/// Persists and retrieves the current navigation session.
abstract class NavigationSessionRepository {
  NavigationSession? get current;

  Future<void> save(NavigationSession session);

  Future<void> clear();
}
