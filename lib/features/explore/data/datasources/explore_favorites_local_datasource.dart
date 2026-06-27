import 'dart:convert';

import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists Explore favorites, collections, and visit history locally.
class ExploreFavoritesLocalDatasource {
  ExploreFavoritesLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _savedKey = 'explore_saved_places';
  static const _recentKey = 'explore_recent_places';
  static const _pinnedKey = 'explore_pinned_places';
  static const _visitedKey = 'explore_visited_places';
  static const _collectionsKey = 'explore_collections';

  List<ExplorePlace> getSavedPlaces() => _readList(_savedKey);
  List<ExplorePlace> getRecentPlaces() => _readList(_recentKey);
  List<ExplorePlace> getPinnedPlaces() => _readList(_pinnedKey);
  List<ExplorePlace> getVisitedPlaces() => _readList(_visitedKey);

  Map<String, List<ExplorePlace>> getCollections() {
    final raw = _prefs.getString(_collectionsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((e) => ExplorePlace.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Future<void> savePlace(ExplorePlace place) async {
    final list = getSavedPlaces();
    if (!list.any((p) => p.id == place.id)) {
      list.insert(0, place);
      await _writeList(_savedKey, list);
    }
  }

  Future<void> removeSavedPlace(String placeId) async {
    final list = getSavedPlaces()..removeWhere((p) => p.id == placeId);
    await _writeList(_savedKey, list);
  }

  Future<void> addToCollection(String collectionName, ExplorePlace place) async {
    final collections = getCollections();
    final list = collections[collectionName] ?? [];
    if (!list.any((p) => p.id == place.id)) {
      list.insert(0, place);
      collections[collectionName] = list;
      await _writeCollections(collections);
    }
  }

  Future<void> removeFromCollection(String collectionName, String placeId) async {
    final collections = getCollections();
    final list = collections[collectionName];
    if (list == null) return;
    list.removeWhere((p) => p.id == placeId);
    collections[collectionName] = list;
    await _writeCollections(collections);
  }

  Future<void> pinPlace(ExplorePlace place) async {
    final list = getPinnedPlaces();
    if (!list.any((p) => p.id == place.id)) {
      list.insert(0, place);
      await _writeList(_pinnedKey, list);
    }
  }

  Future<void> unpinPlace(String placeId) async {
    final list = getPinnedPlaces()..removeWhere((p) => p.id == placeId);
    await _writeList(_pinnedKey, list);
  }

  Future<void> recordVisit(ExplorePlace place) async {
    final list = getVisitedPlaces()..removeWhere((p) => p.id == place.id);
    list.insert(0, place);
    if (list.length > 50) list.removeRange(50, list.length);
    await _writeList(_visitedKey, list);
  }

  Future<void> recordRecent(ExplorePlace place) async {
    final list = getRecentPlaces()..removeWhere((p) => p.id == place.id);
    list.insert(0, place);
    if (list.length > 20) list.removeRange(20, list.length);
    await _writeList(_recentKey, list);
  }

  bool isSaved(String placeId) => getSavedPlaces().any((p) => p.id == placeId);
  bool isPinned(String placeId) => getPinnedPlaces().any((p) => p.id == placeId);

  List<ExplorePlace> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ExplorePlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeList(String key, List<ExplorePlace> places) async {
    final encoded = jsonEncode(places.map((p) => p.toJson()).toList());
    await _prefs.setString(key, encoded);
  }

  Future<void> _writeCollections(Map<String, List<ExplorePlace>> collections) async {
    final encoded = jsonEncode(
      collections.map(
        (key, value) => MapEntry(key, value.map((p) => p.toJson()).toList()),
      ),
    );
    await _prefs.setString(_collectionsKey, encoded);
  }
}
