import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/errors/search_failure.dart';

/// UI state for an active search query.
sealed class SearchQueryState {
  const SearchQueryState();
}

/// No query entered — show recents and saved places.
final class SearchQueryIdle extends SearchQueryState {
  const SearchQueryIdle();
}

/// A search is in flight.
final class SearchQueryLoading extends SearchQueryState {
  const SearchQueryLoading(this.query);

  final String query;
}

/// Matching suggestions are available.
final class SearchQueryResults extends SearchQueryState {
  const SearchQueryResults({
    required this.query,
    required this.places,
  });

  final String query;
  final List<SearchPlace> places;
}

/// Query returned no matches.
final class SearchQueryEmpty extends SearchQueryState {
  const SearchQueryEmpty(this.query);

  final String query;
}

/// Search failed.
final class SearchQueryError extends SearchQueryState {
  const SearchQueryError({
    required this.query,
    required this.failure,
  });

  final String query;
  final SearchFailure failure;
}
