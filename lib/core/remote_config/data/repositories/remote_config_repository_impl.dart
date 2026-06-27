import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/remote_config/data/datasources/remote_config_local_datasource.dart';
import 'package:rihla/core/remote_config/data/datasources/remote_config_remote_datasource.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:rihla/core/remote_config/domain/repositories/remote_config_repository.dart';

class RemoteConfigRepositoryImpl implements RemoteConfigRepository {
  RemoteConfigRepositoryImpl(
    this._local,
    this._remote, {
    required RemoteConfig compileDefaults,
  }) : _compileDefaults = compileDefaults;

  final RemoteConfigLocalDatasource _local;
  final RemoteConfigRemoteDatasource _remote;
  final RemoteConfig _compileDefaults;

  RemoteConfig? _memoryCache;

  @override
  RemoteConfig getCached() =>
      _memoryCache ?? _local.read() ?? _compileDefaults;

  @override
  Future<RemoteConfig> fetchAndCache() async {
    final remote = await _remote.fetch();
    if (remote != null) {
      final merged = _merge(_compileDefaults, remote);
      await _local.write(merged);
      _memoryCache = merged;
      return merged;
    }
    return getCached();
  }

  @override
  Future<void> saveLocal(RemoteConfig config) async {
    await _local.write(config);
    _memoryCache = config;
  }

  /// Remote overrides win over compile defaults; kill switches are unioned.
  RemoteConfig _merge(RemoteConfig base, RemoteConfig remote) => base.copyWith(
        maintenanceMode: remote.maintenanceMode,
        maintenanceMessage: remote.maintenanceMessage,
        aiEnabled: remote.aiEnabled && base.aiEnabled,
        emergencyEnabled: remote.emergencyEnabled,
        exploreEnabled: remote.exploreEnabled,
        offlineEnabled: remote.offlineEnabled,
        cloudSyncEnabled: remote.cloudSyncEnabled && base.cloudSyncEnabled,
        betaFeedbackEnabled: remote.betaFeedbackEnabled,
        uaeIntelligenceEnabled: remote.uaeIntelligenceEnabled,
        regionalRollout: remote.regionalRollout,
        killSwitches: {...base.killSwitches, ...remote.killSwitches},
        rawVersion: remote.rawVersion,
      );
}

RemoteConfig buildCompileDefaults() => RemoteConfig.defaults(
      aiEnabled: ApiConfig.aiEnabled,
      cloudSyncEnabled: ApiConfig.cloudEnabled,
    );
