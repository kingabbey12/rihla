import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/repositories/navigation_session_repository.dart';

/// In-memory store for the current navigation session.
class NavigationSessionRepositoryImpl implements NavigationSessionRepository {
  NavigationSession? _current;

  @override
  NavigationSession? get current => _current;

  @override
  Future<void> save(NavigationSession session) async {
    _current = session;
  }

  @override
  Future<void> clear() async {
    _current = null;
  }
}
