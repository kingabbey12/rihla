export default () => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: parseInt(process.env.PORT ?? '3000', 10),
  apiPrefix: process.env.API_PREFIX ?? 'api/v1',
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:3000').split(','),
  databaseUrl: process.env.DATABASE_URL,
  redisUrl: process.env.REDIS_URL ?? 'redis://localhost:6379',
  supabase: {
    url: process.env.SUPABASE_URL ?? '',
    anonKey: process.env.SUPABASE_ANON_KEY ?? '',
    serviceKey: process.env.SUPABASE_SERVICE_KEY ?? '',
    jwtSecret: process.env.SUPABASE_JWT_SECRET ?? '',
  },
  openaiApiKey: process.env.OPENAI_API_KEY ?? '',
  valhalla: {
    baseUrl:
      process.env.VALHALLA_BASE_URL ?? 'https://valhalla1.openstreetmap.de',
    timeoutMs: parseInt(process.env.VALHALLA_TIMEOUT_MS ?? '30000', 10),
  },
  navigation: {
    offRouteThresholdM: parseInt(
      process.env.NAV_OFF_ROUTE_THRESHOLD_M ?? '80',
      10,
    ),
    arrivalThresholdM: parseInt(
      process.env.NAV_ARRIVAL_THRESHOLD_M ?? '40',
      10,
    ),
    maxSpeedKmh: parseInt(process.env.NAV_MAX_SPEED_KMH ?? '300', 10),
    gpsThrottlePerMinute: parseInt(
      process.env.NAV_GPS_THROTTLE_PER_MIN ?? '120',
      10,
    ),
  },
  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL ?? '60', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT ?? '100', 10),
  },
  openai: {
    apiKey: process.env.OPENAI_API_KEY ?? '',
    model: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
    maxTokens: parseInt(process.env.OPENAI_MAX_TOKENS ?? '800', 10),
    maxInputChars: parseInt(process.env.OPENAI_MAX_INPUT_CHARS ?? '4000', 10),
  },
  nominatim: {
    baseUrl:
      process.env.NOMINATIM_BASE_URL ??
      'https://nominatim.openstreetmap.org',
    userAgent: process.env.NOMINATIM_USER_AGENT ?? 'RihlaApp/1.0',
    uaeViewbox: '51.5,22.5,56.5,26.5',
    countryCode: 'ae',
  },
  overpass: {
    baseUrl:
      process.env.OVERPASS_BASE_URL ?? 'https://overpass-api.de/api/interpreter',
  },
  openChargeMap: {
    baseUrl:
      process.env.OPENCHARGEMAP_BASE_URL ?? 'https://api.openchargemap.io/v3',
    apiKey: process.env.OPENCHARGEMAP_API_KEY ?? '',
  },
  openMeteo: {
    baseUrl: process.env.OPEN_METEO_BASE_URL ?? 'https://api.open-meteo.com',
  },
  tomtom: {
    apiKey: process.env.TOMTOM_API_KEY ?? '',
    baseUrl: process.env.TOMTOM_BASE_URL ?? 'https://api.tomtom.com',
  },
  cache: {
    weatherTtlSeconds: parseInt(process.env.CACHE_WEATHER_TTL ?? '1800', 10),
    trafficTtlSeconds: parseInt(process.env.CACHE_TRAFFIC_TTL ?? '300', 10),
    poiTtlSeconds: parseInt(process.env.CACHE_POI_TTL ?? '7200', 10),
    searchTtlSeconds: parseInt(process.env.CACHE_SEARCH_TTL ?? '600', 10),
  },
  encryption: {
    key: process.env.ENCRYPTION_KEY ?? '',
  },
  shareToken: {
    secret: process.env.SHARE_TOKEN_SECRET ?? process.env.ENCRYPTION_KEY ?? '',
    defaultTtlHours: parseInt(process.env.SHARE_TOKEN_TTL_HOURS ?? '24', 10),
  },
  firebase: {
    serverKey: process.env.FIREBASE_SERVER_KEY ?? '',
    projectId: process.env.FIREBASE_PROJECT_ID ?? '',
  },
  emergency: {
    sosRateLimit: parseInt(process.env.EMERGENCY_SOS_RATE_LIMIT ?? '5', 10),
    locationShareTtlHours: parseInt(process.env.LOCATION_SHARE_TTL_HOURS ?? '24', 10),
  },
  analytics: {
    cacheDashboardTtl: parseInt(process.env.ANALYTICS_CACHE_DASHBOARD_TTL ?? '300', 10),
    cacheLeaderboardTtl: parseInt(process.env.ANALYTICS_CACHE_LEADERBOARD_TTL ?? '600', 10),
    cacheStatisticsTtl: parseInt(process.env.ANALYTICS_CACHE_STATISTICS_TTL ?? '300', 10),
    cacheReportsTtl: parseInt(process.env.ANALYTICS_CACHE_REPORTS_TTL ?? '3600', 10),
    recalculateStaleMinutes: parseInt(process.env.ANALYTICS_RECALC_STALE_MIN ?? '30', 10),
  },
  monitoring: {
    sentryDsn: process.env.SENTRY_DSN ?? '',
    sentryTracesSampleRate: parseFloat(
      process.env.SENTRY_TRACES_SAMPLE_RATE ?? '0.1',
    ),
    otelEnabled: process.env.OTEL_ENABLED === 'true',
  },
});
