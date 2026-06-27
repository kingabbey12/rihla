import 'package:rihla/config/api_config.dart';
import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/domain/entities/auth_provider_type.dart';
import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:rihla/features/account/domain/errors/account_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Production Supabase adapter behind [AccountRemoteDatasource].
class SupabaseAccountRemoteDatasource implements AccountRemoteDatasource {
  SupabaseAccountRemoteDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  bool get isConfigured =>
      ApiConfig.cloudEnabled && ApiConfig.supabaseUrl != null;

  GoTrueClient get _auth => _client.auth;

  @override
  Future<AuthSession> signInWithEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _sessionFromAuth(response.session, AuthProviderType.email);
    } on AuthException catch (e) {
      throw AccountAuthFailure(e.message);
    }
  }

  @override
  Future<AuthSession> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      return _sessionFromAuth(response.session, AuthProviderType.email);
    } on AuthException catch (e) {
      throw AccountAuthFailure(e.message);
    }
  }

  @override
  Future<AuthSession> signInWithOAuth(String provider) async {
    try {
      final oauthProvider = provider == 'google'
          ? OAuthProvider.google
          : OAuthProvider.apple;
      await _auth.signInWithOAuth(oauthProvider);
      final session = _auth.currentSession;
      if (session == null) {
        throw const AccountAuthFailure('OAuth sign-in did not complete');
      }
      return _sessionFromAuth(
        session,
        provider == 'google' ? AuthProviderType.google : AuthProviderType.apple,
      );
    } on AuthException catch (e) {
      throw AccountAuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async => _auth.signOut();

  @override
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.resend(type: OtpType.signup, email: email);
    }
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    final response = await _auth.refreshSession();
    final session = response.session;
    if (session == null) {
      throw const AccountAuthFailure('Session refresh failed');
    }
    return _sessionFromAuth(session, AuthProviderType.email);
  }

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return UserProfile.empty;
    return UserProfile(
      name: row['name'] as String?,
      photoUrl: row['photo_url'] as String?,
      email: row['email'] as String?,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }

  @override
  Future<UserProfile> upsertProfile(String userId, UserProfile profile) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('user_profiles').upsert({
      'user_id': userId,
      'name': profile.name,
      'photo_url': profile.photoUrl,
      'email': profile.email,
      'updated_at': now,
    });
    return profile.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<UserPreferences> fetchPreferences(String userId) async {
    final row = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return UserPreferences.defaults;
    return UserPreferences.fromJson(Map<String, dynamic>.from(row['data'] as Map));
  }

  @override
  Future<UserPreferences> upsertPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'data': preferences.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return preferences.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<RemoteSyncPayload?> fetchCategory(
    String userId,
    SyncCategory category,
  ) async {
    final row = await _client
        .from('user_sync_data')
        .select()
        .eq('user_id', userId)
        .eq('category', category.name)
        .maybeSingle();
    if (row == null) return null;
    return RemoteSyncPayload(
      category: category,
      data: Map<String, dynamic>.from(row['data'] as Map? ?? {}),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      version: row['version'] as int? ?? 1,
    );
  }

  @override
  Future<void> upsertCategory(String userId, RemoteSyncPayload payload) async {
    await _client.from('user_sync_data').upsert({
      'user_id': userId,
      'category': payload.category.name,
      'data': payload.data,
      'updated_at': payload.updatedAt.toIso8601String(),
      'version': payload.version,
    });
  }

  @override
  Future<List<ConnectedDevice>> fetchDevices(String userId) async {
    final rows = await _client
        .from('user_devices')
        .select()
        .eq('user_id', userId);
    return (rows as List<dynamic>)
        .map(
          (row) => ConnectedDevice(
            id: row['device_id'] as String,
            name: row['name'] as String? ?? 'Device',
            platform: row['platform'] as String? ?? 'unknown',
            lastSeenAt: row['last_seen_at'] != null
                ? DateTime.tryParse(row['last_seen_at'] as String)
                : null,
          ),
        )
        .toList();
  }

  @override
  Future<void> registerDevice(String userId, ConnectedDevice device) async {
    await _client.from('user_devices').upsert({
      'user_id': userId,
      'device_id': device.id,
      'name': device.name,
      'platform': device.platform,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await _client.from('user_profiles').delete().eq('user_id', userId);
    await _client.from('user_preferences').delete().eq('user_id', userId);
    await _client.from('user_sync_data').delete().eq('user_id', userId);
    await _client.from('user_devices').delete().eq('user_id', userId);
  }

  @override
  Future<Map<String, dynamic>> exportRemoteData(String userId) async {
    final result = <String, dynamic>{};
    for (final category in SyncCategory.values) {
      final payload = await fetchCategory(userId, category);
      if (payload != null) result[category.name] = payload.data;
    }
    result['profile'] = (await fetchProfile(userId)).toJson();
    result['preferences'] = (await fetchPreferences(userId)).toJson();
    return result;
  }

  AuthSession _sessionFromAuth(Session? session, AuthProviderType provider) {
    if (session == null) {
      throw const AccountAuthFailure('No session returned');
    }
    final user = session.user;
    return AuthSession(
      userId: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      provider: provider,
      emailVerified: user.emailConfirmedAt != null,
      expiresAt: session.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
          : null,
      createdAt: user.createdAt != null
          ? DateTime.tryParse(user.createdAt!)
          : null,
    );
  }
}
