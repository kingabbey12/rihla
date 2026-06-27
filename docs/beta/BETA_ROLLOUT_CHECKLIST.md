# Beta Rollout Checklist — Closed UAE

## Pre-upload
- [ ] Version `2.2.0+22` in `pubspec.yaml` and `AppConfig`
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — all pass
- [ ] `flutter build appbundle` succeeds
- [ ] Production `applicationId` configured (not `com.example.rihla`)
- [ ] Release signing keystore configured
- [ ] `--dart-define` set: `APP_ENV=staging`, analytics/crash enabled, `REMOTE_CONFIG_URL`

## Google Play Internal
- [ ] Upload AAB to Internal testing track
- [ ] Add core team emails as internal testers
- [ ] Smoke test: install, launch, navigate, feedback, emergency test mode

## Google Play Closed (UAE)
- [ ] Promote build to Closed testing track `closed-uae`
- [ ] Add tester list (max 100 for closed)
- [ ] Staged rollout: 10% → monitor 48h → 50% → 100%
- [ ] Store listing notes: “Closed beta — UAE only”

## TestFlight (when ready)
- [ ] Upload IPA via Transporter
- [ ] Internal testing group smoke test
- [ ] External testing group (UAE testers)
- [ ] Export compliance + beta app description

## Post-rollout
- [ ] Verify crash reporting receiving events
- [ ] Verify PostHog/analytics funnels
- [ ] Send tester onboarding email with feedback instructions
- [ ] Schedule daily monitoring for first week
