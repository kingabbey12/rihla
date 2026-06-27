import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/connected_device.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/sync_result.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';

/// Cloud account persistence and authentication boundary.
abstract class AccountRepository {
  AuthSession? get currentSession;

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthSession> signInWithGoogle();
  Future<AuthSession> signInWithApple();
  Future<AuthSession> continueAsGuest();

  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> sendEmailVerification();
  Future<AuthSession> refreshSession();

  Future<AuthSession> upgradeGuestToEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(UserProfile profile);

  Future<UserPreferences> getPreferences();
  Future<UserPreferences> updatePreferences(UserPreferences preferences);

  Future<SyncPrivacySettings> getSyncPrivacySettings();
  Future<SyncPrivacySettings> updateSyncPrivacySettings(
    SyncPrivacySettings settings,
  );

  Future<CloudSyncState> getSyncState();
  Future<SyncResult> syncAll({bool force = false});
  Future<SyncResult> syncCategory(SyncCategory category);

  Future<List<CloudConflict>> getConflicts();
  Future<void> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? manualPayload,
  });

  Future<List<ConnectedDevice>> getConnectedDevices();
  Future<String> exportUserData();
  Future<void> deleteAccount();

  Future<void> enqueueWrite(SyncCategory category, Map<String, dynamic> payload);
  Future<SyncResult> flushQueue();
}
