import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Contract for querying place suggestions (mock or live).
abstract class SearchService {
  /// Returns places matching [query]. Empty [query] returns popular suggestions.
  Future<List<SearchPlace>> suggest(String query);
}
