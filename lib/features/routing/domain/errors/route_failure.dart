/// Typed failures for the routing subsystem.
sealed class RouteFailure {
  const RouteFailure();

  String get message;
}

final class RouteNetworkFailure extends RouteFailure {
  const RouteNetworkFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'Could not reach the routing server.';
}

final class RouteServerFailure extends RouteFailure {
  const RouteServerFailure(this.statusCode, [this.detail]);

  final int statusCode;
  final String? detail;

  @override
  String get message =>
      detail ?? 'Routing server returned an error ($statusCode).';
}

final class RouteParseFailure extends RouteFailure {
  const RouteParseFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'Could not parse the routing response.';
}

final class RouteEmptyFailure extends RouteFailure {
  const RouteEmptyFailure();

  @override
  String get message => 'No routes were found for this journey.';
}

final class RouteUnknownFailure extends RouteFailure {
  const RouteUnknownFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'An unexpected routing error occurred.';
}
