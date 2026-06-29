/// Typed failures for the journey subsystem.
///
/// Each failure carries a short [title] (the headline shown to the user) and a
/// [message] (the explanation). Failures are intentionally specific so the UI
/// never collapses every problem into a single generic "Journey unavailable".
sealed class JourneyFailure {
  const JourneyFailure();

  /// Short headline for the error surface.
  String get title;

  /// Explanation shown under the title.
  String get message;

  /// Optional technical detail surfaced only in debug builds.
  String? get debugDetail => null;
}

/// Generic planning failure (last-resort fallback).
final class JourneyPlanningFailure extends JourneyFailure {
  const JourneyPlanningFailure([this.detail]);

  final String? detail;

  @override
  String get title => 'Journey unavailable';

  @override
  String get message => 'Could not plan this journey. Please try again.';

  @override
  String? get debugDetail => detail;
}

/// Still acquiring the first GPS fix.
final class JourneyLocationWaitingFailure extends JourneyFailure {
  const JourneyLocationWaitingFailure();

  @override
  String get title => 'Waiting for current location…';

  @override
  String get message =>
      'Acquiring your GPS position. This usually takes a few seconds.';
}

/// GPS is unavailable (permission denied, services off, or no signal).
final class JourneyGpsUnavailableFailure extends JourneyFailure {
  const JourneyGpsUnavailableFailure([this.detail]);

  final String? detail;

  @override
  String get title => 'No GPS signal';

  @override
  String get message =>
      detail ?? 'We could not determine your current location.';

  @override
  String? get debugDetail => detail;
}

/// Origin or destination coordinates are invalid (NaN/null/zero/out-of-range).
final class JourneyInvalidCoordinatesFailure extends JourneyFailure {
  const JourneyInvalidCoordinatesFailure({
    required this.endpoint,
    required this.reason,
  });

  /// 'origin' or 'destination'.
  final String endpoint;
  final String reason;

  @override
  String get title => 'Invalid location';

  @override
  String get message =>
      'The $endpoint location is not valid. Please pick another destination.';

  @override
  String? get debugDetail => '$endpoint coordinates invalid: $reason';
}

/// The routing service could not be reached or returned a server error.
final class JourneyRoutingUnavailableFailure extends JourneyFailure {
  const JourneyRoutingUnavailableFailure([this.detail]);

  final String? detail;

  @override
  String get title => 'Routing service unavailable';

  @override
  String get message =>
      'The routing service is not responding right now. Please try again.';

  @override
  String? get debugDetail => detail;
}

/// Network error while planning or routing.
final class JourneyNetworkFailure extends JourneyFailure {
  const JourneyNetworkFailure([this.detail]);

  final String? detail;

  @override
  String get title => 'Network error';

  @override
  String get message =>
      'Check your internet connection and try again.';

  @override
  String? get debugDetail => detail;
}

/// No route could be found between origin and destination.
final class JourneyNoRouteFailure extends JourneyFailure {
  const JourneyNoRouteFailure([this.detail]);

  final String? detail;

  @override
  String get title => 'No route found';

  @override
  String get message =>
      'We could not find a drivable route to this destination.';

  @override
  String? get debugDetail => detail;
}

/// Backwards-compatible alias kept for existing call sites.
final class JourneyOriginUnavailableFailure extends JourneyFailure {
  const JourneyOriginUnavailableFailure();

  @override
  String get title => 'No GPS signal';

  @override
  String get message => 'Your current location is needed to plan a journey.';
}
