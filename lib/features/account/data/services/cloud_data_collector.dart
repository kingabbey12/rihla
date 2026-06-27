import 'dart:convert';

import 'package:rihla/features/account/data/datasources/account_local_datasource.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/explore/data/datasources/explore_favorites_local_datasource.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/offline/data/datasources/offline_download_local_datasource.dart';
import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Collects local data payloads for cloud sync from existing feature stores.
class CloudDataCollector {
  CloudDataCollector({
    required SharedPreferences prefs,
    required AccountLocalDatasource accountLocal,
  })  : _prefs = prefs,
        _accountLocal = accountLocal,
        _search = SearchLocalDataSource(prefs),
        _explore = ExploreFavoritesLocalDatasource(prefs),
        _emergency = EmergencyLocalDatasource(prefs),
        _offline = OfflineDownloadLocalDatasource(prefs);

  final SharedPreferences _prefs;
  final AccountLocalDatasource _accountLocal;
  final SearchLocalDataSource _search;
  final ExploreFavoritesLocalDatasource _explore;
  final EmergencyLocalDatasource _emergency;
  final OfflineDownloadLocalDatasource _offline;

  Map<String, dynamic> collect(SyncCategory category) {
    return switch (category) {
      SyncCategory.favorites => {
          'items': _search.getFavorites().map((p) => p.toJson()).toList(),
        },
      SyncCategory.savedPlaces => {
          'home': _search.getSavedPlace(SavedPlaceKind.home)?.toJson(),
          'work': _search.getSavedPlace(SavedPlaceKind.work)?.toJson(),
        },
      SyncCategory.collections => {
          'collections': _explore.getCollections().map(
                (name, places) => MapEntry(
                  name,
                  places.map((p) => p.toJson()).toList(),
                ),
              ),
        },
      SyncCategory.journeyHistory =>
        _accountLocal.getCategoryData(_accountLocal.journeyHistoryKey),
      SyncCategory.emergencyContacts => {
          'contacts':
              _emergency.getContacts().map((c) => c.toJson()).toList(),
        },
      SyncCategory.vehicleProfile => _emergency.getVehicleProfile().toJson(),
      SyncCategory.medicalProfile => _emergency.getMedicalProfile().toJson(),
      SyncCategory.drivingStatistics =>
        _accountLocal.getCategoryData(_accountLocal.drivingStatsKey),
      SyncCategory.downloadedPreferences => {
          'downloads':
              _offline.getDownloads().map((d) => d.toJson()).toList(),
        },
      SyncCategory.userSettings => {
          'locale': _prefs.getString('locale_code'),
          'theme': _prefs.getString('theme_mode'),
        },
      SyncCategory.aiConversations =>
        _accountLocal.getCategoryData(_accountLocal.aiConversationsKey),
      SyncCategory.journeyReviews =>
        _accountLocal.getCategoryData(_accountLocal.journeyReviewsKey),
      SyncCategory.searchHistory => {
          'recents':
              _search.getRecentSearches().map((p) => p.toJson()).toList(),
        },
      SyncCategory.locationHistory =>
        _accountLocal.getCategoryData(_accountLocal.locationHistoryKey),
    };
  }

  DateTime localUpdatedAt(SyncCategory category) {
    return _accountLocal.getCategoryTimestamp(category.name) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int estimatePayloadBytes(SyncCategory category) {
    return utf8.encode(jsonEncode(collect(category))).length;
  }
}

/// Applies remote sync payloads back into local feature stores.
class CloudDataApplier {
  CloudDataApplier({
    required SharedPreferences prefs,
    required AccountLocalDatasource accountLocal,
  })  : _prefs = prefs,
        _accountLocal = accountLocal,
        _search = SearchLocalDataSource(prefs),
        _explore = ExploreFavoritesLocalDatasource(prefs),
        _emergency = EmergencyLocalDatasource(prefs),
        _offline = OfflineDownloadLocalDatasource(prefs);

  final SharedPreferences _prefs;
  final AccountLocalDatasource _accountLocal;
  final SearchLocalDataSource _search;
  final ExploreFavoritesLocalDatasource _explore;
  final EmergencyLocalDatasource _emergency;
  final OfflineDownloadLocalDatasource _offline;

  Future<void> apply(SyncCategory category, Map<String, dynamic> data) async {
    switch (category) {
      case SyncCategory.favorites:
        final items = (data['items'] as List<dynamic>? ?? [])
            .map((e) => SearchPlace.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final place in items) {
          await _search.addFavorite(place);
        }
      case SyncCategory.savedPlaces:
        final home = data['home'];
        final work = data['work'];
        if (home != null) {
          await _search.setSavedPlace(
            SavedPlaceKind.home,
            SearchPlace.fromJson(home as Map<String, dynamic>),
          );
        }
        if (work != null) {
          await _search.setSavedPlace(
            SavedPlaceKind.work,
            SearchPlace.fromJson(work as Map<String, dynamic>),
          );
        }
      case SyncCategory.collections:
        final collections = data['collections'] as Map<String, dynamic>? ?? {};
        for (final entry in collections.entries) {
          for (final placeJson in entry.value as List<dynamic>) {
            final place =
                ExplorePlace.fromJson(placeJson as Map<String, dynamic>);
            await _explore.addToCollection(entry.key, place);
          }
        }
      case SyncCategory.emergencyContacts:
        final contacts = (data['contacts'] as List<dynamic>? ?? [])
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList();
        await _emergency.saveContacts(contacts);
      case SyncCategory.vehicleProfile:
        await _emergency.saveVehicleProfile(
          EmergencyVehicleProfile.fromJson(data),
        );
      case SyncCategory.medicalProfile:
        await _emergency.saveMedicalProfile(MedicalProfile.fromJson(data));
      case SyncCategory.downloadedPreferences:
        final downloads = (data['downloads'] as List<dynamic>? ?? [])
            .map((e) => OfflineDownload.fromJson(e as Map<String, dynamic>))
            .toList();
        await _offline.saveDownloads(downloads);
      case SyncCategory.userSettings:
        final locale = data['locale'] as String?;
        final theme = data['theme'] as String?;
        if (locale != null) await _prefs.setString('locale_code', locale);
        if (theme != null) await _prefs.setString('theme_mode', theme);
      case SyncCategory.journeyHistory:
        await _accountLocal.saveCategoryData(
          _accountLocal.journeyHistoryKey,
          data,
        );
      case SyncCategory.drivingStatistics:
        await _accountLocal.saveCategoryData(
          _accountLocal.drivingStatsKey,
          data,
        );
      case SyncCategory.aiConversations:
        await _accountLocal.saveCategoryData(
          _accountLocal.aiConversationsKey,
          data,
        );
      case SyncCategory.journeyReviews:
        await _accountLocal.saveCategoryData(
          _accountLocal.journeyReviewsKey,
          data,
        );
      case SyncCategory.searchHistory:
        final recents = (data['recents'] as List<dynamic>? ?? [])
            .map((e) => SearchPlace.fromJson(e as Map<String, dynamic>))
            .toList();
        await _search.saveRecentSearches(recents);
      case SyncCategory.locationHistory:
        await _accountLocal.saveCategoryData(
          _accountLocal.locationHistoryKey,
          data,
        );
    }
    await _accountLocal.setCategoryTimestamp(category.name, DateTime.now());
  }
}
