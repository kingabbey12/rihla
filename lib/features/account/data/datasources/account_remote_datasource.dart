import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';

/// Remote payload for a sync category.
class RemoteSyncPayload {
  const RemoteSyncPayload({
    required this.category,
    required this.data,
    required this.updatedAt,
    this.version = 1,
  });

  final SyncCategory category;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
  final int version;
}

/// Cloud backend boundary (Supabase or stub).
abstract class AccountRemoteDatasource {
  bool get isConfigured;

  Future<AuthSession> signInWithEmail(String email, String password);
  Future<AuthSession> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  });
  Future<AuthSession> signInWithOAuth(String provider);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> sendEmailVerification();
  Future<AuthSession> refreshSession(String refreshToken);

  Future<UserProfile> fetchProfile(String userId);
  Future<UserProfile> upsertProfile(String userId, UserProfile profile);

  Future<UserPreferences> fetchPreferences(String userId);
  Future<UserPreferences> upsertPreferences(
    String userId,
    UserPreferences preferences,
  );

  Future<RemoteSyncPayload?> fetchCategory(
    String userId,
    SyncCategory category,
  );
  Future<void> upsertCategory(
    String userId,
    RemoteSyncPayload payload,
  );

  Future<List<ConnectedDevice>> fetchDevices(String userId);
  Future<void> registerDevice(String userId, ConnectedDevice device);
  Future<void> deleteAccount(String userId);
  Future<Map<String, dynamic>> exportRemoteData(String userId);
}
