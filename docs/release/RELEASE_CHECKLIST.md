# Release Checklist

Use for every production release to App Store / Google Play.

## 1. Pre-flight
- [ ] `main` is green (CI) and all PRs for the release are merged.
- [ ] Version bumped in `pubspec.yaml` (`version: X.Y.Z+build`).
- [ ] Release notes drafted (`docs/store/STORE_LISTING.md`).
- [ ] No secrets committed; all keys provided via `--dart-define` in the build pipeline.

## 2. Verification
- [ ] `flutter analyze` — 0 errors.
- [ ] `flutter test` — all pass.
- [ ] `integration_test/` E2E suite passes on at least one physical device.
- [ ] `flutter build apk --release` succeeds.
- [ ] `flutter build appbundle` succeeds.
- [ ] `flutter build ios --release` succeeds (macOS environment).

## 3. Configuration
- [ ] Production `--dart-define`s set: Supabase, AI proxy, `ANALYTICS_ENABLED`, `CRASH_REPORTING_ENABLED`, `CERT_SPKI_PINS`, `POSTHOG_*`.
- [ ] Firebase config files present (`google-services.json`, `GoogleService-Info.plist`).
- [ ] Map style/API keys valid for production quota.

## 4. Store assets
- [ ] Icons, adaptive icons, splash, launch screens regenerated.
- [ ] Screenshots + feature graphic uploaded.
- [ ] Privacy nutrition labels (Apple) / Data Safety form (Google) match `docs/legal/`.
- [ ] Privacy Policy & Terms URLs live.

## 5. Sign-off
- [ ] Smoke test signed build on Android + iOS: launch, search, route, navigate, emergency (test mode), offline toggle, AI prompt.
- [ ] Crash reporting receiving events from the signed build.
- [ ] Analytics receiving key events.
- [ ] Tag the release commit: `vX.Y-<name>`.

## 6. Rollout
- [ ] Staged rollout: Google Play 10% → 50% → 100%; Apple phased release on.
- [ ] Monitor crash-free sessions for 24–48 h before widening.
