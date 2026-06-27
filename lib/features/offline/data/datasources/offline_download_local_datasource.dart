import 'dart:convert';

import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists download queue and progress.
class OfflineDownloadLocalDatasource {
  OfflineDownloadLocalDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _keyDownloads = 'offline_downloads';
  static const _keyDismissed = 'offline_dismissed_suggestions';

  List<OfflineDownload> getDownloads() {
    final raw = _prefs.getString(_keyDownloads);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OfflineDownload.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDownloads(List<OfflineDownload> downloads) async {
    await _prefs.setString(
      _keyDownloads,
      jsonEncode(downloads.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> upsert(OfflineDownload download) async {
    final list = getDownloads();
    final index = list.indexWhere((d) => d.id == download.id);
    if (index >= 0) {
      list[index] = download;
    } else {
      list.add(download);
    }
    await saveDownloads(list);
  }

  Future<void> remove(String downloadId) async {
    final list = getDownloads()..removeWhere((d) => d.id == downloadId);
    await saveDownloads(list);
  }

  Set<String> getDismissedSuggestions() {
    return _prefs.getStringList(_keyDismissed)?.toSet() ?? {};
  }

  Future<void> dismissSuggestion(String key) async {
    final set = getDismissedSuggestions()..add(key);
    await _prefs.setStringList(_keyDismissed, set.toList());
  }
}
