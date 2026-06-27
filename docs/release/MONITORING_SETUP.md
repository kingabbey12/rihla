# Monitoring Setup — Rihla v1.0.0

Rihla ships a backend-agnostic observability boundary (`lib/core/observability/`).
Everything is **opt-in** and **sanitized** (`LogSanitizer`) before transmission.

## 1. What's wired in code

| Capability | Code surface | Enable flag |
| --- | --- | --- |
| Crash reporting | `CrashReporter` + global hooks in `main.dart` (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`) | `CRASH_REPORTING_ENABLED=true` |
| Product analytics | `AnalyticsService` / `PostHogAnalyticsService`, `AnalyticsEvent` | `ANALYTICS_ENABLED=true`, `POSTHOG_API_KEY` |
| Breadcrumbs | `Breadcrumb` via `AppLogger` (navigation/AI/emergency/offline) | follows crash flag |
| Remote configuration | `lib/core/remote_config/` (`remoteConfigControllerProvider`) | `REMOTE_CONFIG_URL` |
| Feature flags / kill switches | `RemoteConfig` (`aiEnabled`, `isKillSwitchActive`, `maintenanceMode`, regional rollout) | served via remote config |
| Beta/product metrics | `BetaMetricsService`, `trackProductEvent` | on-device |

## 2. Crashlytics

The `CrashReporter` interface is provider-injected
(`crashReporterProvider`). To route to Firebase Crashlytics:
1. Add `firebase_core` + `firebase_crashlytics`, plus `google-services.json` /
   `GoogleService-Info.plist` (git-ignored).
2. Implement `CrashReporter` backed by `FirebaseCrashlytics.instance` and
   override `crashReporterProvider` in `main.dart` (replacing
   `BufferingCrashReporter`). No call sites change.
3. Upload native symbols for both platforms in the release pipeline.

Until the Firebase adapter is added, builds use `BufferingCrashReporter`
(enabled) or `NoOpCrashReporter` (disabled). Crash-free sessions are also tracked
on-device via `BetaMetricsService`.

## 3. PostHog / Analytics

Set `ANALYTICS_ENABLED=true`, `POSTHOG_API_KEY`, and `POSTHOG_HOST`.
`PostHogAnalyticsService` posts sanitized `AnalyticsEvent`s. Canonical events:
`appOpened`, `journeyStarted`, `journeyCompleted`, `navigationCancelled`,
`emergencyActivated`, `offlineDownload`, `exploreUsage`, `aiUsage`,
`searchSuccess`, `searchFailure`.

## 4. Performance Monitoring

App startup, frame, and image-cache budgets are configured via
`PerformanceConfig` (`lib/core/performance/`). For a hosted backend, add Firebase
Performance alongside the Crashlytics adapter and emit custom traces for
journey-start latency and route computation.

## 5. Remote Configuration & Feature Flags

Set `REMOTE_CONFIG_URL` to a JSON endpoint matching the `RemoteConfig` schema.
On startup `_AccountBootstrap` calls `remoteConfigControllerProvider.refresh()`.
Use it for: AI enable/disable, emergency toggles, regional rollout, maintenance
mode, and kill switches. Existing features read flags through
`remoteConfigProvider` selectors — never hard-coded values.

Example payload:
```json
{
  "aiEnabled": true,
  "emergencyEnabled": true,
  "maintenanceMode": false,
  "killSwitches": [],
  "regionalRollout": { "AE": true }
}
```

## 6. Verification before launch
- [ ] Production build sends a test event visible in PostHog.
- [ ] Forced crash appears in the crash backend (once Firebase adapter added).
- [ ] Remote config fetch succeeds and a flag toggle is observed in-app.
- [ ] Kill switch disables a feature without an app update.
