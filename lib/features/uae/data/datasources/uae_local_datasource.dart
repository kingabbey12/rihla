import 'dart:convert';

import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UaeLocalDatasource {
  UaeLocalDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _prefsKey = 'uae_preferences';
  static const _snapshotKey = 'uae_last_snapshot_region';

  UaePreferences getPreferences() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return UaePreferences.defaults;
    return UaePreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePreferences(UaePreferences preferences) async {
    await _prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
  }

  String? getLastSnapshotRegion() => _prefs.getString(_snapshotKey);

  Future<void> saveSnapshotRegion(String region) async {
    await _prefs.setString(_snapshotKey, region);
  }
}
