import 'dart:convert';
import 'dart:math';

import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/domain/entities/auth_provider_type.dart';
import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local stub remote backend for dev, tests, and offline-first operation.
class StubAccountRemoteDatasource implements AccountRemoteDatasource {
  StubAccountRemoteDatasource(this._prefs);

  final SharedPreferences _prefs;
  final _random = Random();

  static const _usersPrefix = 'stub_cloud_users_';
  static const _syncPrefix = 'stub_cloud_sync_';

  @override
  bool get isConfigured => true;

  @override
  Future<AuthSession> signInWithEmail(String email, String password) async {
    final userId = _userIdForEmail(email);
    final session = AuthSession(
      userId: userId,
      email: email,
      displayName: email.split('@').first,
      provider: AuthProviderType.email,
      emailVerified: true,
      createdAt: DateTime.now(),
      accessToken: 'stub_token_$userId',
      refreshToken: 'stub_refresh_$userId',
    );
    await _saveUser(userId, {'email': email, 'password': password});
    return session;
  }

  @override
  Future<AuthSession> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final session = await signInWithEmail(email, password);
    await upsertProfile(
      session.userId,
      UserProfile(
        name: displayName ?? session.displayName,
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return session.copyWith(displayName: displayName);
  }

  @override
  Future<AuthSession> signInWithOAuth(String provider) async {
    final userId = 'oauth_${provider}_${_random.nextInt(99999)}';
    return AuthSession(
      userId: userId,
      email: '$userId@rihla.app',
      displayName: provider,
      provider: provider == 'google'
          ? AuthProviderType.google
          : AuthProviderType.apple,
      emailVerified: true,
      createdAt: DateTime.now(),
      accessToken: 'stub_oauth_$userId',
      refreshToken: 'stub_oauth_refresh_$userId',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    final userId = refreshToken.replaceFirst('stub_refresh_', '');
    return AuthSession(
      userId: userId,
      accessToken: 'stub_token_$userId',
      refreshToken: refreshToken,
      emailVerified: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final raw = _prefs.getString('$_usersPrefix${userId}_profile');
    if (raw == null) return UserProfile.empty;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> upsertProfile(String userId, UserProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _prefs.setString(
      '$_usersPrefix${userId}_profile',
      jsonEncode(updated.toJson()),
    );
    return updated;
  }

  @override
  Future<UserPreferences> fetchPreferences(String userId) async {
    final raw = _prefs.getString('$_usersPrefix${userId}_prefs');
    if (raw == null) return UserPreferences.defaults;
    return UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<UserPreferences> upsertPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    final updated = preferences.copyWith(updatedAt: DateTime.now());
    await _prefs.setString(
      '$_usersPrefix${userId}_prefs',
      jsonEncode(updated.toJson()),
    );
    return updated;
  }

  @override
  Future<RemoteSyncPayload?> fetchCategory(
    String userId,
    SyncCategory category,
  ) async {
    final raw = _prefs.getString('$_syncPrefix${userId}_${category.name}');
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return RemoteSyncPayload(
      category: category,
      data: Map<String, dynamic>.from(decoded['data'] as Map? ?? {}),
      updatedAt: DateTime.parse(decoded['updatedAt'] as String),
      version: decoded['version'] as int? ?? 1,
    );
  }

  @override
  Future<void> upsertCategory(String userId, RemoteSyncPayload payload) async {
    await _prefs.setString(
      '$_syncPrefix${userId}_${payload.category.name}',
      jsonEncode({
        'data': payload.data,
        'updatedAt': payload.updatedAt.toIso8601String(),
        'version': payload.version,
      }),
    );
  }

  @override
  Future<List<ConnectedDevice>> fetchDevices(String userId) async {
    final raw = _prefs.getString('$_usersPrefix${userId}_devices');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ConnectedDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> registerDevice(String userId, ConnectedDevice device) async {
    final devices = await fetchDevices(userId);
    final updated = [
      ...devices.where((d) => d.id != device.id),
      device,
    ];
    await _prefs.setString(
      '$_usersPrefix${userId}_devices',
      jsonEncode(updated.map((d) => d.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteAccount(String userId) async {
    final keys = _prefs.getKeys().where(
      (k) => k.startsWith('$_usersPrefix$userId') || k.startsWith('$_syncPrefix$userId'),
    );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  @override
  Future<Map<String, dynamic>> exportRemoteData(String userId) async {
    final result = <String, dynamic>{};
    for (final category in SyncCategory.values) {
      final payload = await fetchCategory(userId, category);
      if (payload != null) {
        result[category.name] = payload.data;
      }
    }
    result['profile'] = (await fetchProfile(userId)).toJson();
    result['preferences'] = (await fetchPreferences(userId)).toJson();
    return result;
  }

  String _userIdForEmail(String email) =>
      'user_${email.hashCode.abs()}';

  Future<void> _saveUser(String userId, Map<String, String> data) async {
    await _prefs.setString('$_usersPrefix$userId', jsonEncode(data));
  }
}
