import 'dart:convert';

import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent searches and saved places locally via [SharedPreferences].
class SearchLocalDataSource {
  SearchLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _keyRecent = 'search_recent_places';
  static const _keyHome = 'search_saved_home';
  static const _keyWork = 'search_saved_work';
  static const _keyFavorites = 'search_saved_favorites';
  static const _maxRecent = 10;

  List<SearchPlace> getRecentSearches() {
    final raw = _prefs.getString(_keyRecent);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SearchPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentSearches(List<SearchPlace> places) async {
    final encoded = jsonEncode(places.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyRecent, encoded);
  }

  Future<void> addRecentSearch(SearchPlace place) async {
    final current = getRecentSearches()
      ..removeWhere((p) => p.id == place.id)
      ..insert(0, place);
    if (current.length > _maxRecent) {
      current.removeRange(_maxRecent, current.length);
    }
    await saveRecentSearches(current);
  }

  Future<void> removeRecentSearch(String placeId) async {
    final current = getRecentSearches()..removeWhere((p) => p.id == placeId);
    await saveRecentSearches(current);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_keyRecent);
  }

  SearchPlace? _readPlace(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return SearchPlace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePlace(String key, SearchPlace? place) async {
    if (place == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, jsonEncode(place.toJson()));
    }
  }

  SearchPlace? getSavedPlace(SavedPlaceKind kind) => switch (kind) {
        SavedPlaceKind.home => _readPlace(_keyHome),
        SavedPlaceKind.work => _readPlace(_keyWork),
      };

  Future<void> setSavedPlace(SavedPlaceKind kind, SearchPlace? place) =>
      _writePlace(switch (kind) {
        SavedPlaceKind.home => _keyHome,
        SavedPlaceKind.work => _keyWork,
      }, place);

  List<SearchPlace> getFavorites() {
    final raw = _prefs.getString(_keyFavorites);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SearchPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<SearchPlace> places) async {
    final encoded = jsonEncode(places.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyFavorites, encoded);
  }

  Future<void> addFavorite(SearchPlace place) async {
    final current = getFavorites();
    if (current.any((p) => p.id == place.id)) return;
    current.add(place);
    await saveFavorites(current);
  }

  Future<void> removeFavorite(String placeId) async {
    final current = getFavorites()..removeWhere((p) => p.id == placeId);
    await saveFavorites(current);
  }

  bool isFavorite(String placeId) =>
      getFavorites().any((p) => p.id == placeId);
}
