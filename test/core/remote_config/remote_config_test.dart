import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';

void main() {
  group('RemoteConfig', () {
    test('defaults enable UAE regional rollout', () {
      const config = RemoteConfig();
      expect(config.isRegionEnabled('AE'), isTrue);
      expect(config.isRegionEnabled('US'), isFalse);
    });

    test('kill switch disables feature checks', () {
      const config = RemoteConfig(
        aiEnabled: true,
        killSwitches: {'ai': true},
      );
      expect(config.isKillSwitchActive('ai'), isTrue);
    });

    test('merge respects compile-time AI gate', () {
      const compile = RemoteConfig(aiEnabled: false);
      const remote = RemoteConfig(aiEnabled: true);
      final result = compile.copyWith(
        aiEnabled: remote.aiEnabled && compile.aiEnabled,
      );
      expect(result.aiEnabled, isFalse);
    });
  });
}
