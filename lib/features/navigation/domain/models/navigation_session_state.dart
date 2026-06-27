import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';

/// Controller state for the navigation session subsystem.
sealed class NavigationSessionState {
  const NavigationSessionState();
}

/// No active navigation session.
final class NavigationSessionInactive extends NavigationSessionState {
  const NavigationSessionInactive();
}

/// An active navigation session with live updates.
final class NavigationSessionActive extends NavigationSessionState {
  const NavigationSessionActive(this.session);

  final NavigationSession session;
}
