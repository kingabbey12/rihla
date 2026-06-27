import 'dart:convert';

import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigLocalDatasource {
  RemoteConfigLocalDatasource(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'remote_config_v1';

  RemoteConfig? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return RemoteConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(RemoteConfig config) async {
    await _prefs.setString(_key, jsonEncode(config.toJson()));
  }
}
