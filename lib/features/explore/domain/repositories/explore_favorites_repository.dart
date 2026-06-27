import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Local favorites, collections, and visit history for Explore.
abstract class ExploreFavoritesRepository {
  List<ExplorePlace> getSavedPlaces();
  List<ExplorePlace> getRecentPlaces();
  List<ExplorePlace> getPinnedPlaces();
  List<ExplorePlace> getVisitedPlaces();
  Map<String, List<ExplorePlace>> getCollections();

  Future<void> savePlace(ExplorePlace place);
  Future<void> removeSavedPlace(String placeId);
  Future<void> addToCollection(String collectionName, ExplorePlace place);
  Future<void> removeFromCollection(String collectionName, String placeId);
  Future<void> pinPlace(ExplorePlace place);
  Future<void> unpinPlace(String placeId);
  Future<void> recordVisit(ExplorePlace place);
  Future<void> recordRecent(ExplorePlace place);
  bool isSaved(String placeId);
  bool isPinned(String placeId);
}
