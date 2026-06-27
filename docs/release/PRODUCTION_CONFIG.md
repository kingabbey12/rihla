# Production Configuration — Rihla v1.0.0

This document is the single source of truth for building and releasing the
public production version of Rihla.

## 1. Identity

| Item | Value |
| --- | --- |
| App name | Rihla |
| Android `applicationId` / `namespace` | `com.rihla.app` |
| iOS bundle identifier | `com.rihla.app` |
| Marketing version | `1.0.0` |
| Build number (versionCode / CFBundleVersion) | `100` |

Version source of truth is `pubspec.yaml` (`version: 1.0.0+100`). Android reads
`flutter.versionName` / `flutter.versionCode`; iOS reads the generated values.
`lib/config/app_config.dart` mirrors these for in-app display.

> Build number 100 intentionally exceeds the closed-beta codes (…+22) so Google
> Play accepts the production upload.

## 2. Environment

Production is selected at build time with `--dart-define=APP_ENV=production`
(`AppEnvironment.production`). Release channel defaults to `production`
(`AppConfig.releaseChannel`, override with `--dart-define=RELEASE_CHANNEL=...`).

## 3. Production secrets (compile-time `--dart-define`)

No secrets are committed. They are injected at build time (locally via a defines
file, in CI via the `DART_DEFINES` secret). Keys consumed by `ApiConfig`:

```
APP_ENV=production
# Observability (opt-in)
CRASH_REPORTING_ENABLED=true
ANALYTICS_ENABLED=true
POSTHOG_API_KEY=phc_xxx
POSTHOG_HOST=https://eu.posthog.com
# Remote config
REMOTE_CONFIG_URL=https://config.rihla.app/v1/remote_config.json
# Security
CERT_SPKI_PINS=sha256/AAAA...;sha256/BBBB...
# Backend / data providers (fill real values)
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
OPENAI_API_KEY=...   # or OPENAI_PROXY_URL
TOMTOM_API_KEY=...
OPENCHARGEMAP_API_KEY=...
```

Local example build:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=CRASH_REPORTING_ENABLED=true \
  --dart-define=ANALYTICS_ENABLED=true \
  --dart-define=POSTHOG_API_KEY=phc_xxx \
  --dart-define=REMOTE_CONFIG_URL=https://config.rihla.app/v1/remote_config.json
```

## 4. Release signing (Android)

1. Generate the upload keystore (once) and store it securely (1Password / CI secret):
   ```bash
   keytool -genkey -v -keystore rihla-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias rihla-upload
   ```
2. Copy `android/key.properties.example` → `android/key.properties` and fill in
   `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. `android/app/build.gradle.kts` auto-detects `key.properties` and signs release
   builds with it. Without the file, release builds fall back to debug signing
   (so local `flutter run --release` still works).
4. Enroll in **Google Play App Signing**; the upload key signs uploads, Google
   re-signs for distribution.

`key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.p8`, `.env*`,
`google-services.json`, and `GoogleService-Info.plist` are git-ignored.

## 5. Release signing (iOS)

1. In Xcode, set the Runner target Team and enable automatic signing, or use
   `fastlane match` for managed certificates/profiles.
2. Bundle identifier is already `com.rihla.app` across configs.
3. Archive via `flutter build ipa --release` (or the `Release` workflow on macOS).

## 6. Build minification

Release builds enable R8 (`isMinifyEnabled` + `isShrinkResources`) with keep
rules in `android/app/proguard-rules.pro` covering Flutter, MapLibre, geolocator,
permission_handler, and Supabase/OkHttp reflection paths.
