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

  /// Developer map overlay (FPS, GPS, camera, style). Hidden by default; only
  /// shown when running a debug build with --dart-define=SHOW_DEBUG_OVERLAY=true.
  /// Never visible during normal app usage or in release builds.
  static const bool showDebugOverlay = bool.fromEnvironment(
    'SHOW_DEBUG_OVERLAY',
  );
}
