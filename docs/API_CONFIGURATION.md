# API Configuration Guide

Rihla reads all API endpoints and keys from compile-time `--dart-define` values via `lib/config/api_config.dart`. No secrets are embedded in widgets or repositories.

## Environments

| Variable | Values | Default |
|----------|--------|---------|
| `APP_ENV` | `development`, `staging`, `production` | `development` |

## Required for core features (no key)

| Service | Variable | Default |
|---------|----------|---------|
| Geocoding (Nominatim) | `NOMINATIM_BASE_URL` | `https://nominatim.openstreetmap.org` |
| Routing (Valhalla) | `VALHALLA_BASE_URL` | `https://valhalla1.openstreetmap.de` |
| Weather (Open-Meteo) | `OPEN_METEO_BASE_URL` | `https://api.open-meteo.com` |
| Hazards (Overpass) | `OVERPASS_BASE_URL` | `https://overpass-api.de/api/interpreter` |

Set a custom User-Agent for Nominatim:

```
NOMINATIM_USER_AGENT=Rihla/1.0 (you@example.com)
```

## Optional keys (enhanced data)

| Service | Variables |
|---------|-----------|
| Traffic (TomTom) | `TOMTOM_API_KEY`, `TOMTOM_BASE_URL` |
| EV charging | `OPENCHARGEMAP_API_KEY`, `OPENCHARGEMAP_BASE_URL` |
| Fuel prices | `FUEL_API_BASE_URL`, `FUEL_API_KEY` |
| Parking | `PARKING_API_BASE_URL`, `PARKING_API_KEY` |
| AI (disabled until approved) | `OPENAI_API_KEY` |

When TomTom is not configured, traffic falls back to time-of-day heuristics. Fuel and parking fall back to OpenStreetMap Overpass queries.

## Build examples

### Development

```bash
flutter run
```

### Staging

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=TOMTOM_API_KEY=your_key
```

### Production release

```bash
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=NOMINATIM_USER_AGENT="Rihla/1.0 (ops@rihla.app)" \
  --dart-define=TOMTOM_API_KEY=your_key \
  --dart-define=OPENCHARGEMAP_API_KEY=your_key
```

## Architecture

All HTTP traffic flows through `ApiClient` (`lib/core/network/api_client.dart`):

- Retry with exponential backoff
- Configurable timeout
- In-memory response cache with TTL
- Per-host rate limiting
- Offline stale-cache fallback
- Typed `ApiException` hierarchy
- Debug request logging

Feature datasources never call `http` directly.

## AI provider

`ApiConfig.aiEnabled` is **hardcoded to `false`**. The OpenAI integration exists but will not activate until explicitly approved in a future phase.
