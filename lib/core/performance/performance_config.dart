import 'package:flutter/painting.dart';

/// Centralized performance tuning applied at startup.
abstract final class PerformanceConfig {
  /// Image cache caps. The default Flutter cache (1000 items / 100 MB) is large
  /// for a map-heavy app; tightening it reduces memory pressure on low-end
  /// devices while keeping enough headroom for explore thumbnails and icons.
  static const int imageCacheMaxItems = 200;
  static const int imageCacheMaxBytes = 64 * 1024 * 1024; // 64 MB

  /// Applies image-cache limits. Safe to call after binding init.
  static void apply() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = imageCacheMaxItems;
    cache.maximumSizeBytes = imageCacheMaxBytes;
  }
}
