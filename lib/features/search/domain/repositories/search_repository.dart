import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// High-level search operations including local persistence.
abstract class SearchRepository {
  Future<List<SearchPlace>> search(String query);

  Future<List<SearchPlace>> getRecentSearches();

  Future<void> addRecentSearch(SearchPlace place);

  Future<void> removeRecentSearch(String placeId);

  Future<void> clearRecentSearches();

  Future<SearchPlace?> getSavedPlace(SavedPlaceKind kind);

  Future<void> setSavedPlace(SavedPlaceKind kind, SearchPlace? place);

  Future<List<SearchPlace>> getFavorites();

  Future<void> addFavorite(SearchPlace place);

  Future<void> removeFavorite(String placeId);

  Future<bool> isFavorite(String placeId);
}
