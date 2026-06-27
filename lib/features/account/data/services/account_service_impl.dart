import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/sync_result.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:rihla/features/account/domain/repositories/account_repository.dart';
import 'package:rihla/features/account/domain/services/account_service.dart';

class AccountServiceImpl implements AccountService {
  AccountServiceImpl(this._repository);

  final AccountRepository _repository;

  @override
  AuthSession? get session => _repository.currentSession;

  @override
  Future<AuthSession> signInWithEmail(String email, String password) =>
      _repository.signInWithEmail(email: email, password: password);

  @override
  Future<AuthSession> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) =>
      _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

  @override
  Future<AuthSession> signInWithGoogle() => _repository.signInWithGoogle();

  @override
  Future<AuthSession> signInWithApple() => _repository.signInWithApple();

  @override
  Future<AuthSession> continueAsGuest() => _repository.continueAsGuest();

  @override
  Future<void> signOut() => _repository.signOut();

  @override
  Future<void> resetPassword(String email) =>
      _repository.resetPassword(email);

  @override
  Future<void> verifyEmail() => _repository.sendEmailVerification();

  @override
  Future<AuthSession> refreshSession() => _repository.refreshSession();

  @override
  Future<AuthSession> upgradeGuest(String email, String password) =>
      _repository.upgradeGuestToEmail(email: email, password: password);

  @override
  Future<UserProfile> getProfile() => _repository.getProfile();

  @override
  Future<UserProfile> updateProfile(UserProfile profile) =>
      _repository.updateProfile(profile);

  @override
  Future<UserPreferences> getPreferences() => _repository.getPreferences();

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) =>
      _repository.updatePreferences(preferences);

  @override
  Future<SyncPrivacySettings> getPrivacySettings() =>
      _repository.getSyncPrivacySettings();

  @override
  Future<SyncPrivacySettings> updatePrivacySettings(
    SyncPrivacySettings settings,
  ) =>
      _repository.updateSyncPrivacySettings(settings);

  @override
  Future<SyncResult> synchronize({bool force = false}) =>
      _repository.syncAll(force: force);

  @override
  Future<SyncResult> synchronizeCategory(SyncCategory category) =>
      _repository.syncCategory(category);

  @override
  Future<void> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? manualPayload,
  }) =>
      _repository.resolveConflict(
        conflictId,
        strategy,
        manualPayload: manualPayload,
      );

  @override
  Future<String> exportData() => _repository.exportUserData();

  @override
  Future<void> deleteAccount() => _repository.deleteAccount();
}
