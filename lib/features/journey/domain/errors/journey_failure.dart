/// Typed failures for the journey subsystem.
sealed class JourneyFailure {
  const JourneyFailure();

  String get message;
}

final class JourneyPlanningFailure extends JourneyFailure {
  const JourneyPlanningFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'Could not plan this journey.';
}

final class JourneyOriginUnavailableFailure extends JourneyFailure {
  const JourneyOriginUnavailableFailure();

  @override
  String get message => 'Your current location is needed to plan a journey.';
}
