import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/sync_result.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';

/// High-level account operations orchestrating auth and sync.
abstract class AccountService {
  AuthSession? get session;

  Future<AuthSession> signInWithEmail(String email, String password);
  Future<AuthSession> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  });
  Future<AuthSession> signInWithGoogle();
  Future<AuthSession> signInWithApple();
  Future<AuthSession> continueAsGuest();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> verifyEmail();
  Future<AuthSession> refreshSession();
  Future<AuthSession> upgradeGuest(String email, String password);

  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<UserPreferences> getPreferences();
  Future<UserPreferences> updatePreferences(UserPreferences preferences);

  Future<SyncPrivacySettings> getPrivacySettings();
  Future<SyncPrivacySettings> updatePrivacySettings(SyncPrivacySettings settings);

  Future<SyncResult> synchronize({bool force = false});
  Future<SyncResult> synchronizeCategory(SyncCategory category);
  Future<void> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? manualPayload,
  });

  Future<String> exportData();
  Future<void> deleteAccount();
}
