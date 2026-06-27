/// Application-wide configuration constants.
abstract final class AppConfig {
  static const String appName = 'Rihla';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '100';

  /// Release channel: 'production' for the public store build, 'closed-uae'
  /// for the closed beta. Override at build time via --dart-define=RELEASE_CHANNEL.
  static const String releaseChannel = String.fromEnvironment(
    'RELEASE_CHANNEL',
    defaultValue: 'production',
  );
}
