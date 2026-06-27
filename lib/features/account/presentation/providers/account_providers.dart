import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/beta_feedback/presentation/providers/beta_feedback_providers.dart';
import 'package:rihla/features/account/data/datasources/account_local_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_secure_storage.dart';
import 'package:rihla/features/account/data/datasources/account_sync_queue_datasource.dart';
import 'package:rihla/features/account/data/datasources/stub_account_remote_datasource.dart';
import 'package:rihla/features/account/data/datasources/supabase_account_remote_datasource.dart';
import 'package:rihla/features/account/data/repositories/account_repository_impl.dart';
import 'package:rihla/features/account/data/services/account_service_impl.dart';
import 'package:rihla/features/account/data/services/cloud_data_collector.dart';
import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/user_preferences.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:rihla/features/account/domain/errors/account_failure.dart';
import 'package:rihla/features/account/domain/models/account_state.dart';
import 'package:rihla/features/account/domain/repositories/account_repository.dart';
import 'package:rihla/features/account/domain/services/account_service.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

// —— Infrastructure ————————————————————————————————————————————————————————

final accountSecureStorageProvider = Provider<AccountSecureStorage>(
  (ref) => AccountSecureStorage(),
);

final accountLocalDatasourceProvider = Provider<AccountLocalDatasource>((ref) {
  return AccountLocalDatasource(ref.watch(sharedPreferencesProvider));
});

final accountSyncQueueProvider = Provider<AccountSyncQueueDatasource>((ref) {
  return AccountSyncQueueDatasource(ref.watch(sharedPreferencesProvider));
});

final accountRemoteDatasourceProvider = Provider<AccountRemoteDatasource>((ref) {
  if (ApiConfig.cloudEnabled) {
    return SupabaseAccountRemoteDatasource();
  }
  return StubAccountRemoteDatasource(ref.watch(sharedPreferencesProvider));
});

final cloudDataCollectorProvider = Provider<CloudDataCollector>((ref) {
  return CloudDataCollector(
    prefs: ref.watch(sharedPreferencesProvider),
    accountLocal: ref.watch(accountLocalDatasourceProvider),
  );
});

final cloudDataApplierProvider = Provider<CloudDataApplier>((ref) {
  return CloudDataApplier(
    prefs: ref.watch(sharedPreferencesProvider),
    accountLocal: ref.watch(accountLocalDatasourceProvider),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    local: ref.watch(accountLocalDatasourceProvider),
    remote: ref.watch(accountRemoteDatasourceProvider),
    queue: ref.watch(accountSyncQueueProvider),
    secureStorage: ref.watch(accountSecureStorageProvider),
    collector: ref.watch(cloudDataCollectorProvider),
    applier: ref.watch(cloudDataApplierProvider),
    isConnected: () => ref.read(networkConnectivityStateProvider),
  );
});

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountServiceImpl(ref.watch(accountRepositoryProvider));
});

final accountSyncStateProvider = FutureProvider<CloudSyncState>((ref) async {
  return ref.watch(accountRepositoryProvider).getSyncState();
});

final accountPrivacySettingsProvider =
    Provider<SyncPrivacySettings>((ref) {
  return ref.watch(accountLocalDatasourceProvider).getPrivacySettings();
});

// —— Controller ———————————————————————————————————————————————————————————————

final accountControllerProvider =
    NotifierProvider<AccountController, AccountState>(AccountController.new);

class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() {
    final session = ref.read(accountRepositoryProvider).currentSession;
    if (session == null) return const AccountInitial();
    if (session.isGuest) return AccountGuest(session: session);
    return AccountSignedIn(
      session: session,
      profile: ref.read(accountLocalDatasourceProvider).getProfile(),
      syncState: ref.read(accountLocalDatasourceProvider).getSyncState(),
    );
  }

  Future<void> initialize() async {
    final repo = ref.read(accountRepositoryProvider);
    final session = repo.currentSession;
    if (session == null) {
      state = const AccountInitial();
      return;
    }
    if (session.isGuest) {
      state = AccountGuest(session: session);
      return;
    }
    await _loadSignedIn(session);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AccountLoading();
    try {
      final session = await ref
          .read(accountServiceProvider)
          .signInWithEmail(email, password);
      await _loadSignedIn(session);
    } on AccountFailure catch (e) {
      state = AccountError(message: e.message, previous: state);
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = const AccountLoading();
    try {
      final session = await ref.read(accountServiceProvider).signUpWithEmail(
            email,
            password,
            displayName: displayName,
          );
      await _loadSignedIn(session);
    } on AccountFailure catch (e) {
      state = AccountError(message: e.message, previous: state);
    }
  }

  Future<void> signInWithGoogle() async => _socialSignIn(
        ref.read(accountServiceProvider).signInWithGoogle,
      );

  Future<void> signInWithApple() async => _socialSignIn(
        ref.read(accountServiceProvider).signInWithApple,
      );

  Future<void> _socialSignIn(
    Future<AuthSession> Function() signIn,
  ) async {
    state = const AccountLoading();
    try {
      final session = await signIn();
      await _loadSignedIn(session);
    } on AccountFailure catch (e) {
      state = AccountError(message: e.message, previous: state);
    }
  }

  Future<void> continueAsGuest() async {
    state = const AccountLoading();
    final session =
        await ref.read(accountServiceProvider).continueAsGuest();
    state = AccountGuest(session: session);
  }

  Future<void> upgradeGuest(String email, String password) async {
    state = const AccountLoading();
    try {
      final session = await ref
          .read(accountServiceProvider)
          .upgradeGuest(email, password);
      await _loadSignedIn(session);
    } on AccountFailure catch (e) {
      state = AccountError(message: e.message, previous: state);
    }
  }

  Future<void> signOut() async {
    await ref.read(accountServiceProvider).signOut();
    state = const AccountInitial();
  }

  Future<void> resetPassword(String email) =>
      ref.read(accountServiceProvider).resetPassword(email);

  Future<void> verifyEmail() =>
      ref.read(accountServiceProvider).verifyEmail();

  Future<void> refreshSession() async {
    try {
      final session = await ref.read(accountServiceProvider).refreshSession();
      await _loadSignedIn(session);
    } on AccountFailure catch (e) {
      state = AccountError(message: e.message, previous: state);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final updated =
        await ref.read(accountServiceProvider).updateProfile(profile);
    if (state is AccountSignedIn) {
      final current = state as AccountSignedIn;
      state = AccountSignedIn(
        session: current.session,
        profile: updated,
        syncState: current.syncState,
        conflicts: current.conflicts,
      );
    }
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    await ref.read(accountServiceProvider).updatePreferences(preferences);
  }

  Future<void> updatePrivacySettings(SyncPrivacySettings settings) async {
    await ref.read(accountServiceProvider).updatePrivacySettings(settings);
    ref.invalidate(accountPrivacySettingsProvider);
  }

  Future<void> synchronize({bool force = false}) async {
    if (state is! AccountSignedIn) return;
    final current = state as AccountSignedIn;
    state = AccountSignedIn(
      session: current.session,
      profile: current.profile,
      syncState: current.syncState.copyWith(status: CloudSyncStatus.syncing),
      conflicts: current.conflicts,
    );
    final result =
        await ref.read(accountServiceProvider).synchronize(force: force);
    final syncState = await ref.read(accountRepositoryProvider).getSyncState();
    final conflicts = await ref.read(accountRepositoryProvider).getConflicts();
    state = AccountSignedIn(
      session: current.session,
      profile: current.profile,
      syncState: syncState.copyWith(
        status: result.conflicts.isNotEmpty
            ? CloudSyncStatus.conflict
            : CloudSyncStatus.idle,
        lastSyncAt: result.syncedAt,
      ),
      conflicts: conflicts,
    );
    if (result.conflicts.isEmpty) {
      await ref.read(betaMetricsServiceProvider).recordCloudSyncSuccess();
    } else {
      await ref.read(betaMetricsServiceProvider).recordCloudSyncFailure();
    }
  }

  Future<void> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy,
  ) async {
    await ref.read(accountServiceProvider).resolveConflict(
          conflictId,
          strategy,
        );
    await synchronize(force: true);
  }

  Future<String> exportData() =>
      ref.read(accountServiceProvider).exportData();

  Future<void> deleteAccount() async {
    await ref.read(accountServiceProvider).deleteAccount();
    state = const AccountInitial();
  }

  Future<void> togglePrivacyCategory(SyncCategory category, bool enabled) async {
    final current = ref.read(accountPrivacySettingsProvider);
    await updatePrivacySettings(current.withCategory(category, enabled));
  }

  Future<void> _loadSignedIn(AuthSession session) async {
    final profile = await ref.read(accountServiceProvider).getProfile();
    final syncState = await ref.read(accountRepositoryProvider).getSyncState();
    final conflicts = await ref.read(accountRepositoryProvider).getConflicts();
    state = AccountSignedIn(
      session: session,
      profile: profile,
      syncState: syncState,
      conflicts: conflicts,
    );
  }
}
