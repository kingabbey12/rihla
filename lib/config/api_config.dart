import 'package:rihla/config/app_environment.dart';

/// Centralized API endpoints and keys — never embed secrets in widgets.
///
/// Pass values via `--dart-define`:
///   APP_ENV=development|staging|production
///   VALHALLA_BASE_URL=https://...
///   NOMINATIM_BASE_URL=https://...
///   OPEN_METEO_BASE_URL=https://...
///   TOMTOM_API_KEY=...
///   OPENCHARGEMAP_API_KEY=...
///   FUEL_API_BASE_URL=...
///   PARKING_API_BASE_URL=...
abstract final class ApiConfig {
  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment =>
      AppEnvironment.fromString(_envName);

  // —— Geocoding (Nominatim / OSM) ————————————————————————————————————————

  static String get nominatimBaseUrl => switch (environment) {
        AppEnvironment.production => const String.fromEnvironment(
            'NOMINATIM_BASE_URL',
            defaultValue: 'https://nominatim.openstreetmap.org',
          ),
        AppEnvironment.staging => const String.fromEnvironment(
            'NOMINATIM_BASE_URL',
            defaultValue: 'https://nominatim.openstreetmap.org',
          ),
        AppEnvironment.development => const String.fromEnvironment(
            'NOMINATIM_BASE_URL',
            defaultValue: 'https://nominatim.openstreetmap.org',
          ),
      };

  static const String nominatimUserAgent = String.fromEnvironment(
    'NOMINATIM_USER_AGENT',
    defaultValue: 'Rihla/1.0 (contact@rihla.app)',
  );

  // —— Routing (Valhalla) ——————————————————————————————————————————————————

  static String get valhallaBaseUrl => switch (environment) {
        AppEnvironment.production => const String.fromEnvironment(
            'VALHALLA_BASE_URL',
            defaultValue: 'https://valhalla1.openstreetmap.de',
          ),
        AppEnvironment.staging => const String.fromEnvironment(
            'VALHALLA_BASE_URL',
            defaultValue: 'https://valhalla1.openstreetmap.de',
          ),
        AppEnvironment.development => const String.fromEnvironment(
            'VALHALLA_BASE_URL',
            defaultValue: 'https://valhalla1.openstreetmap.de',
          ),
      };

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int defaultMaxRetries = 2;

  // —— Weather (Open-Meteo — no key required) ——————————————————————————————

  static String get openMeteoBaseUrl => const String.fromEnvironment(
        'OPEN_METEO_BASE_URL',
        defaultValue: 'https://api.open-meteo.com',
      );

  // —— Traffic (TomTom — key optional, offline fallback when absent) ———————

  static String? get tomtomApiKey {
    const key = String.fromEnvironment('TOMTOM_API_KEY');
    return key.isEmpty ? null : key;
  }

  static String get tomtomBaseUrl => const String.fromEnvironment(
        'TOMTOM_BASE_URL',
        defaultValue: 'https://api.tomtom.com',
      );

  // —— Hazards (Overpass / OSM) ————————————————————————————————————————————

  static String get overpassBaseUrl => const String.fromEnvironment(
        'OVERPASS_BASE_URL',
        defaultValue: 'https://overpass-api.de/api/interpreter',
      );

  // —— EV charging (OpenChargeMap) ————————————————————————————————————————

  static String? get openChargeMapApiKey {
    const key = String.fromEnvironment('OPENCHARGEMAP_API_KEY');
    return key.isEmpty ? null : key;
  }

  static String get openChargeMapBaseUrl => const String.fromEnvironment(
        'OPENCHARGEMAP_BASE_URL',
        defaultValue: 'https://api.openchargemap.io/v3',
      );

  // —— Fuel prices (configurable provider) —————————————————————————————————

  static String? get fuelApiBaseUrl {
    const url = String.fromEnvironment('FUEL_API_BASE_URL');
    return url.isEmpty ? null : url;
  }

  static String? get fuelApiKey {
    const key = String.fromEnvironment('FUEL_API_KEY');
    return key.isEmpty ? null : key;
  }

  // —— Parking (configurable provider) ————————————————————————————————————

  static String? get parkingApiBaseUrl {
    const url = String.fromEnvironment('PARKING_API_BASE_URL');
    return url.isEmpty ? null : url;
  }

  static String? get parkingApiKey {
    const key = String.fromEnvironment('PARKING_API_KEY');
    return key.isEmpty ? null : key;
  }

  // —— AI (OpenAI / proxy via dart-define) —————————————————————————————————

  /// Backend proxy URL — when set, requests route through your server instead
  /// of calling OpenAI directly from the device.
  static String? get openAiProxyUrl {
    const url = String.fromEnvironment('OPENAI_PROXY_URL');
    return url.isEmpty ? null : url;
  }

  static String get openAiBaseUrl {
    final proxy = openAiProxyUrl;
    if (proxy != null) return proxy;
    return const String.fromEnvironment(
      'OPENAI_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    );
  }

  static String? get openAiApiKey {
    const key = String.fromEnvironment('OPENAI_API_KEY');
    return key.isEmpty ? null : key;
  }

  static String get openAiModel => const String.fromEnvironment(
        'OPENAI_MODEL',
        defaultValue: 'gpt-4o-mini',
      );

  /// AI is enabled when AI_ENABLED=true (dart-define) and a key or proxy is set.
  static bool get aiEnabled {
    const flag = String.fromEnvironment('AI_ENABLED', defaultValue: 'true');
    if (flag.toLowerCase() != 'true') return false;
    return openAiApiKey != null || openAiProxyUrl != null;
  }

  static Duration get openAiTimeout => const Duration(
        seconds: int.fromEnvironment('OPENAI_TIMEOUT_SECONDS', defaultValue: 30),
      );

  // —— Supabase (cloud platform) ———————————————————————————————————————————

  static String? get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    return url.isEmpty ? null : url;
  }

  static String? get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    return key.isEmpty ? null : key;
  }

  /// Cloud sync enabled when Supabase is configured.
  static bool get cloudEnabled =>
      supabaseUrl != null && supabaseAnonKey != null;
}
