import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';

abstract class RemoteConfigRepository {
  RemoteConfig getCached();
  Future<RemoteConfig> fetchAndCache();
  Future<void> saveLocal(RemoteConfig config);
}
