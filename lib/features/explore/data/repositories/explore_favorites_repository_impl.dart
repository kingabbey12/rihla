import 'package:rihla/features/explore/data/datasources/explore_favorites_local_datasource.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/repositories/explore_favorites_repository.dart';

class ExploreFavoritesRepositoryImpl implements ExploreFavoritesRepository {
  ExploreFavoritesRepositoryImpl(this._local);

  final ExploreFavoritesLocalDatasource _local;

  @override
  List<ExplorePlace> getSavedPlaces() => _local.getSavedPlaces();

  @override
  List<ExplorePlace> getRecentPlaces() => _local.getRecentPlaces();

  @override
  List<ExplorePlace> getPinnedPlaces() => _local.getPinnedPlaces();

  @override
  List<ExplorePlace> getVisitedPlaces() => _local.getVisitedPlaces();

  @override
  Map<String, List<ExplorePlace>> getCollections() => _local.getCollections();

  @override
  Future<void> savePlace(ExplorePlace place) => _local.savePlace(place);

  @override
  Future<void> removeSavedPlace(String placeId) =>
      _local.removeSavedPlace(placeId);

  @override
  Future<void> addToCollection(String collectionName, ExplorePlace place) =>
      _local.addToCollection(collectionName, place);

  @override
  Future<void> removeFromCollection(String collectionName, String placeId) =>
      _local.removeFromCollection(collectionName, placeId);

  @override
  Future<void> pinPlace(ExplorePlace place) => _local.pinPlace(place);

  @override
  Future<void> unpinPlace(String placeId) => _local.unpinPlace(placeId);

  @override
  Future<void> recordVisit(ExplorePlace place) => _local.recordVisit(place);

  @override
  Future<void> recordRecent(ExplorePlace place) => _local.recordRecent(place);

  @override
  bool isSaved(String placeId) => _local.isSaved(placeId);

  @override
  bool isPinned(String placeId) => _local.isPinned(placeId);
}
