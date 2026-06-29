import 'package:flutter/foundation.dart';

/// Capability check for the native MapLibre engine.
///
/// `maplibre_gl` ships native implementations only for Android, iOS and web.
/// On other platforms (macOS, Windows, Linux) the plugin's platform view
/// returns a "not supported" placeholder and never fires `onMapCreated` /
/// `onStyleLoadedCallback`, which would leave the user staring at a blank
/// surface. Use this to render a graceful fallback instead.
abstract final class MapPlatformSupport {
  /// True when the current platform can host a live MapLibre map.
  static bool get supportsNativeMap {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
