/// Valhalla routing server configuration.
abstract final class ValhallaConfig {
  /// Public OSM-hosted Valhalla instance for development.
  static const String defaultBaseUrl = 'https://valhalla1.openstreetmap.de';

  static const String routePath = '/route';

  static const Duration requestTimeout = Duration(seconds: 30);

  static const int defaultAlternates = 3;
}
