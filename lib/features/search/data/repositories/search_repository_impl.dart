import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';

/// Coordinates mock search suggestions with local persistence.
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._service, this._local);

  final SearchService _service;
  final SearchLocalDataSource _local;

  @override
  Future<List<SearchPlace>> search(String query) => _service.suggest(query);

  @override
  Future<List<SearchPlace>> getRecentSearches() async =>
      _local.getRecentSearches();

  @override
  Future<void> addRecentSearch(SearchPlace place) =>
      _local.addRecentSearch(place);

  @override
  Future<void> removeRecentSearch(String placeId) =>
      _local.removeRecentSearch(placeId);

  @override
  Future<void> clearRecentSearches() => _local.clearRecentSearches();

  @override
  Future<SearchPlace?> getSavedPlace(SavedPlaceKind kind) async =>
      _local.getSavedPlace(kind);

  @override
  Future<void> setSavedPlace(SavedPlaceKind kind, SearchPlace? place) =>
      _local.setSavedPlace(kind, place);

  @override
  Future<List<SearchPlace>> getFavorites() async => _local.getFavorites();

  @override
  Future<void> addFavorite(SearchPlace place) => _local.addFavorite(place);

  @override
  Future<void> removeFavorite(String placeId) =>
      _local.removeFavorite(placeId);

  @override
  Future<bool> isFavorite(String placeId) async => _local.isFavorite(placeId);
}
