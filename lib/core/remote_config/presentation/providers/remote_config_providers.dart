import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/remote_config/data/datasources/remote_config_local_datasource.dart';
import 'package:rihla/core/remote_config/data/datasources/remote_config_remote_datasource.dart';
import 'package:rihla/core/remote_config/data/repositories/remote_config_repository_impl.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:rihla/core/remote_config/domain/repositories/remote_config_repository.dart';

final remoteConfigLocalDatasourceProvider =
    Provider<RemoteConfigLocalDatasource>(
  (ref) => RemoteConfigLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final remoteConfigRemoteDatasourceProvider =
    Provider<RemoteConfigRemoteDatasource>(
  (ref) => RemoteConfigRemoteDatasource(),
);

final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>(
  (ref) => RemoteConfigRepositoryImpl(
    ref.watch(remoteConfigLocalDatasourceProvider),
    ref.watch(remoteConfigRemoteDatasourceProvider),
    compileDefaults: buildCompileDefaults(),
  ),
);

/// Effective runtime configuration — compile defaults merged with cached remote.
final remoteConfigProvider = Provider<RemoteConfig>(
  (ref) => ref.watch(remoteConfigRepositoryProvider).getCached(),
);

/// Fetches remote overrides and refreshes [remoteConfigProvider].
final remoteConfigControllerProvider =
    AsyncNotifierProvider<RemoteConfigController, RemoteConfig>(
  RemoteConfigController.new,
);

class RemoteConfigController extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() async {
    final repo = ref.read(remoteConfigRepositoryProvider);
    return repo.fetchAndCache();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(remoteConfigRepositoryProvider).fetchAndCache(),
    );
  }
}

/// Convenience selectors — use these instead of [ApiConfig] flags in features.
final aiFeatureEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).aiEnabled &&
      !ref.watch(remoteConfigProvider).isKillSwitchActive('ai'),
);

final emergencyFeatureEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).emergencyEnabled &&
      !ref.watch(remoteConfigProvider).isKillSwitchActive('emergency'),
);

final maintenanceModeProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).maintenanceMode,
);
