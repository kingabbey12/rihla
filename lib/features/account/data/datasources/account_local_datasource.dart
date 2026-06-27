import 'dart:convert';

import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for account state, profile, and sync metadata.
class AccountLocalDatasource {
  AccountLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'account_session';
  static const _profileKey = 'account_profile';
  static const _preferencesKey = 'account_preferences';
  static const _privacyKey = 'account_sync_privacy';
  static const _syncStateKey = 'account_sync_state';
  static const _conflictsKey = 'account_conflicts';
  static const _devicesKey = 'account_devices';
  static const _journeyHistoryKey = 'account_journey_history';
  static const _drivingStatsKey = 'account_driving_statistics';
  static const _journeyReviewsKey = 'account_journey_reviews';
  static const _aiConversationsKey = 'account_ai_conversations';
  static const _locationHistoryKey = 'account_location_history';
  static const _categoryTimestampsKey = 'account_category_timestamps';

  AuthSession? getSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AuthSession? session) async {
    if (session == null) {
      await _prefs.remove(_sessionKey);
    } else {
      await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    }
  }

  UserProfile getProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return UserProfile.empty;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  UserPreferences getPreferences() {
    final raw = _prefs.getString(_preferencesKey);
    if (raw == null) return UserPreferences.defaults;
    return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    await _prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
  }

  SyncPrivacySettings getPrivacySettings() {
    final raw = _prefs.getString(_privacyKey);
    if (raw == null) return SyncPrivacySettings.defaults;
    return SyncPrivacySettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> savePrivacySettings(SyncPrivacySettings settings) async {
    await _prefs.setString(_privacyKey, jsonEncode(settings.toJson()));
  }

  CloudSyncState getSyncState() {
    final raw = _prefs.getString(_syncStateKey);
    if (raw == null) return CloudSyncState.initial;
    return CloudSyncState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSyncState(CloudSyncState state) async {
    await _prefs.setString(_syncStateKey, jsonEncode(state.toJson()));
  }

  List<CloudConflict> getConflicts() {
    final raw = _prefs.getString(_conflictsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CloudConflict.fromJson(e as Map<String, dynamic>))
        .where((c) => !c.isResolved)
        .toList();
  }

  Future<void> saveConflicts(List<CloudConflict> conflicts) async {
    await _prefs.setString(
      _conflictsKey,
      jsonEncode(conflicts.map((c) => c.toJson()).toList()),
    );
  }

  List<ConnectedDevice> getDevices() {
    final raw = _prefs.getString(_devicesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ConnectedDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDevices(List<ConnectedDevice> devices) async {
    await _prefs.setString(
      _devicesKey,
      jsonEncode(devices.map((d) => d.toJson()).toList()),
    );
  }

  Map<String, dynamic> getCategoryData(String categoryKey) {
    final raw = _prefs.getString(categoryKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCategoryData(String categoryKey, Map<String, dynamic> data) {
    return _prefs.setString(categoryKey, jsonEncode(data));
  }

  String get journeyHistoryKey => _journeyHistoryKey;
  String get drivingStatsKey => _drivingStatsKey;
  String get journeyReviewsKey => _journeyReviewsKey;
  String get aiConversationsKey => _aiConversationsKey;
  String get locationHistoryKey => _locationHistoryKey;

  DateTime? getCategoryTimestamp(String category) {
    final raw = _prefs.getString(_categoryTimestampsKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final value = map[category] as String?;
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<void> setCategoryTimestamp(String category, DateTime time) async {
    final raw = _prefs.getString(_categoryTimestampsKey);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    map[category] = time.toIso8601String();
    await _prefs.setString(_categoryTimestampsKey, jsonEncode(map));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_sessionKey);
    await _prefs.remove(_profileKey);
    await _prefs.remove(_preferencesKey);
    await _prefs.remove(_privacyKey);
    await _prefs.remove(_syncStateKey);
    await _prefs.remove(_conflictsKey);
    await _prefs.remove(_devicesKey);
    await _prefs.remove(_journeyHistoryKey);
    await _prefs.remove(_drivingStatsKey);
    await _prefs.remove(_journeyReviewsKey);
    await _prefs.remove(_aiConversationsKey);
    await _prefs.remove(_locationHistoryKey);
    await _prefs.remove(_categoryTimestampsKey);
  }
}
