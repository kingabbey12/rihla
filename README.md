# Rihla

**Rihla** is an offline-ready navigation app built for the UAE: turn-by-turn
navigation, live safety advisories (Salik, speed cameras, driving rules),
emergency SOS, an AI copilot, and Explore (fuel, parking, charging). English &
Arabic with full right-to-left support. Private by default.

> Version **1.0.0** — first public release.

## Features
- Offline maps & navigation (tunnels, parking, remote roads)
- UAE intelligence: Salik / speed-camera / driving-rule / weather advisories
- Emergency SOS with encrypted medical profile & contacts
- AI copilot for journey help
- Explore nearby places
- Optional cloud sync (account) for places & preferences
- Privacy-first: analytics/crash reporting off by default; sensitive data encrypted

## Tech stack
Flutter · Riverpod · go_router · MapLibre GL · Supabase (optional cloud) ·
flutter_secure_storage. Clean architecture (`domain`/`data`/`presentation`) per
feature under `lib/features/`. Cross-cutting code in `lib/core/`.

## Getting started

```bash
flutter pub get
flutter run
```

Secrets and provider keys are supplied at build time via `--dart-define`
(never hard-coded). See `docs/release/PRODUCTION_CONFIG.md` for the full list.

Example production build:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=ANALYTICS_ENABLED=true \
  --dart-define=REMOTE_CONFIG_URL=https://config.rihla.app/v1/remote_config.json
```

## Quality

```bash
flutter analyze
flutter test
```

## Release & operations
- Production config & signing: `docs/release/PRODUCTION_CONFIG.md`
- Monitoring setup: `docs/release/MONITORING_SETUP.md`
- Store submission: `docs/store/STORE_SUBMISSION.md`
- Release / rollback / hotfix / versioning: `docs/release/`
- Operations (dashboards, incidents, alerts, escalation): `docs/operations/`
- Support workflow & knowledge base: `docs/support/`
- Release notes / known issues / roadmap: `docs/release/`
- CI/CD: `.github/workflows/ci.yml` (PRs) and `release.yml` (tagged releases)

## Legal
Privacy Policy, Terms of Service, and disclaimers live in `docs/legal/` and on the
marketing site (`website/`). Safety advisories are informational only; emergency
tools are a convenience aid, not a substitute for official services
(UAE: 999 / 998 / 997).

## App identity
- Application ID / bundle ID: `com.rihla.app`
- Version: `1.0.0+100`
