import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/account/data/datasources/account_local_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_remote_datasource.dart';
import 'package:rihla/features/account/data/datasources/account_secure_storage.dart';
import 'package:rihla/features/account/data/datasources/account_sync_queue_datasource.dart';
import 'package:rihla/features/account/data/datasources/stub_account_remote_datasource.dart';
import 'package:rihla/features/account/data/repositories/account_repository_impl.dart';
import 'package:rihla/features/account/data/services/cloud_data_collector.dart';
import 'package:rihla/features/account/data/services/conflict_resolver.dart';
import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/entities/sync_privacy_settings.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';
import 'package:rihla/features/account/domain/models/account_state.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AccountRepositoryImpl repository;
  late StubAccountRemoteDatasource remote;
  late Map<String, String> secureMemory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    secureMemory = {};
    final local = AccountLocalDatasource(prefs);
    remote = StubAccountRemoteDatasource(prefs);
    repository = AccountRepositoryImpl(
      local: local,
      remote: remote,
      queue: AccountSyncQueueDatasource(prefs),
      secureStorage: AccountSecureStorage(memoryStore: secureMemory),
      collector: CloudDataCollector(prefs: prefs, accountLocal: local),
      applier: CloudDataApplier(prefs: prefs, accountLocal: local),
      isConnected: () => true,
    );
  });

  group('Authentication', () {
    test('email sign in creates session', () async {
      final session = await repository.signInWithEmail(
        email: 'driver@rihla.app',
        password: 'secret123',
      );
      expect(session.email, 'driver@rihla.app');
      expect(repository.currentSession?.isGuest, isFalse);
    });

    test('guest mode creates guest session', () async {
      final session = await repository.continueAsGuest();
      expect(session.isGuest, isTrue);
      expect(repository.currentSession?.userId, 'guest');
    });

    test('sign out clears session', () async {
      await repository.signInWithEmail(
        email: 'a@rihla.app',
        password: 'pass',
      );
      await repository.signOut();
      expect(repository.currentSession, isNull);
    });

    test('google sign in works via stub', () async {
      final session = await repository.signInWithGoogle();
      expect(session.provider.name, 'google');
    });

    test('password reset does not throw', () async {
      await expectLater(
        repository.resetPassword('reset@rihla.app'),
        completes,
      );
    });
  });

  group('Guest upgrade', () {
    test('guest can upgrade to email account', () async {
      await repository.continueAsGuest();
      final session = await repository.upgradeGuestToEmail(
        email: 'upgraded@rihla.app',
        password: 'newpass',
      );
      expect(session.isGuest, isFalse);
      expect(session.email, 'upgraded@rihla.app');
    });
  });

  group('Profile updates', () {
    test('profile persists locally and remotely', () async {
      await repository.signInWithEmail(
        email: 'profile@rihla.app',
        password: 'pass',
      );
      final updated = await repository.updateProfile(
        const UserProfile(name: 'Ade', email: 'profile@rihla.app'),
      );
      expect(updated.name, 'Ade');
      final fetched = await repository.getProfile();
      expect(fetched.name, 'Ade');
    });
  });

  group('Cloud sync', () {
    test('syncAll pushes local favorites', () async {
      await repository.signInWithEmail(
        email: 'sync@rihla.app',
        password: 'pass',
      );
      final result = await repository.syncAll();
      expect(result.success, isTrue);
      expect(result.syncedCategories, isNotEmpty);
    });

    test('syncCategory respects privacy disabled', () async {
      await repository.signInWithEmail(
        email: 'privacy@rihla.app',
        password: 'pass',
      );
      await repository.updateSyncPrivacySettings(
        SyncPrivacySettings.defaults.withCategory(
          SyncCategory.medicalProfile,
          false,
        ),
      );
      final result = await repository.syncCategory(SyncCategory.medicalProfile);
      expect(result.success, isTrue);
    });
  });

  group('Conflict resolution', () {
    test('newest wins prefers remote when newer', () {
      final resolver = ConflictResolver();
      final conflict = CloudConflict(
        id: 'c1',
        category: SyncCategory.favorites,
        localUpdatedAt: DateTime(2024),
        remoteUpdatedAt: DateTime(2025),
        localPayload: const {'v': 'local'},
        remotePayload: const {'v': 'remote'},
      );
      final resolved = resolver.resolve(
        conflict: conflict,
        strategy: ConflictResolutionStrategy.newestWins,
      );
      expect(resolved['v'], 'remote');
    });

    test('local wins keeps local payload', () {
      final resolver = ConflictResolver();
      final conflict = CloudConflict(
        id: 'c2',
        category: SyncCategory.favorites,
        localUpdatedAt: DateTime(2024),
        remoteUpdatedAt: DateTime(2025),
        localPayload: const {'v': 'local'},
        remotePayload: const {'v': 'remote'},
      );
      final resolved = resolver.resolve(
        conflict: conflict,
        strategy: ConflictResolutionStrategy.localWins,
      );
      expect(resolved['v'], 'local');
    });

    test('manual resolution uses provided payload', () {
      final resolver = ConflictResolver();
      final conflict = CloudConflict(
        id: 'c3',
        category: SyncCategory.favorites,
        localUpdatedAt: DateTime(2024),
        remoteUpdatedAt: DateTime(2025),
        localPayload: const {'v': 'local'},
        remotePayload: const {'v': 'remote'},
      );
      final resolved = resolver.resolve(
        conflict: conflict,
        strategy: ConflictResolutionStrategy.manual,
        manualPayload: const {'v': 'manual'},
      );
      expect(resolved['v'], 'manual');
    });
  });

  group('Offline queue', () {
    test('enqueueWrite queues when offline', () async {
      final offlineRepo = AccountRepositoryImpl(
        local: AccountLocalDatasource(prefs),
        remote: remote,
        queue: AccountSyncQueueDatasource(prefs),
        secureStorage: AccountSecureStorage(memoryStore: {}),
        collector: CloudDataCollector(
          prefs: prefs,
          accountLocal: AccountLocalDatasource(prefs),
        ),
        applier: CloudDataApplier(
          prefs: prefs,
          accountLocal: AccountLocalDatasource(prefs),
        ),
        isConnected: () => false,
      );
      await offlineRepo.signInWithEmail(
        email: 'offline@rihla.app',
        password: 'pass',
      );
      await offlineRepo.enqueueWrite(
        SyncCategory.favorites,
        const {'items': []},
      );
      final state = await offlineRepo.getSyncState();
      expect(state.pendingWrites, greaterThan(0));
    });

    test('flushQueue syncs queued writes on reconnect', () async {
      await repository.signInWithEmail(
        email: 'queue@rihla.app',
        password: 'pass',
      );
      await repository.enqueueWrite(
        SyncCategory.userSettings,
        const {'locale': 'en'},
      );
      final result = await repository.flushQueue();
      expect(result.success, isTrue);
    });
  });

  group('AccountController', () {
    test('sign in transitions to signed in state', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRemoteDatasourceProvider.overrideWith((ref) => remote),
          accountSecureStorageProvider.overrideWith(
            (ref) => AccountSecureStorage(memoryStore: {}),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountControllerProvider.notifier)
          .signInWithEmail('ctrl@rihla.app', 'pass');

      expect(
        container.read(accountControllerProvider),
        isA<AccountSignedIn>(),
      );
    });

    test('guest mode transitions to guest state', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountRemoteDatasourceProvider.overrideWith((ref) => remote),
          accountSecureStorageProvider.overrideWith(
            (ref) => AccountSecureStorage(memoryStore: {}),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountControllerProvider.notifier).continueAsGuest();
      expect(container.read(accountControllerProvider), isA<AccountGuest>());
    });
  });

  group('Settings / export', () {
    test('exportUserData returns json payload', () async {
      await repository.signInWithEmail(
        email: 'export@rihla.app',
        password: 'pass',
      );
      final exported = await repository.exportUserData();
      expect(exported, contains('profile'));
      expect(exported, contains('preferences'));
    });

    test('privacy settings default medical off', () {
      final settings = SyncPrivacySettings.defaults;
      expect(settings.isEnabled(SyncCategory.medicalProfile), isFalse);
      expect(settings.isEnabled(SyncCategory.favorites), isTrue);
    });
  });
}
