/// Typed failures for the search subsystem.
sealed class SearchFailure {
  const SearchFailure();

  String get message;
}

/// Local persistence read/write failed.
final class SearchStorageFailure extends SearchFailure {
  const SearchStorageFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'Could not save search data.';
}

/// The mock search provider failed unexpectedly.
final class SearchServiceFailure extends SearchFailure {
  const SearchServiceFailure([this.detail]);

  final String? detail;

  @override
  String get message => detail ?? 'Search is temporarily unavailable.';
}
