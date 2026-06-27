import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';

/// Delegates search to online or offline repository based on connectivity.
class OfflineAwareSearchRepository implements SearchRepository {
  OfflineAwareSearchRepository({
    required this.isOffline,
    required SearchRepository online,
    required SearchRepository offline,
    required SearchLocalDataSource local,
  })  : _online = online,
        _offline = offline,
        _local = local;

  final bool Function() isOffline;
  final SearchRepository _online;
  final SearchRepository _offline;
  final SearchLocalDataSource _local;

  SearchRepository get _active => isOffline() ? _offline : _online;

  @override
  Future<List<SearchPlace>> search(String query) => _active.search(query);

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
  Future<bool> isFavorite(String placeId) async =>
      _local.isFavorite(placeId);
}
