# Phase 19 — Closed UAE Beta Program

**Goal:** Prepare, execute, and monitor the first closed beta with real UAE users.
**Scope:** Bug fixes, stability, telemetry, beta tooling only — no major new features.
**Version:** 2.2.0+22 · Tag: `v2.2-closed-beta` · Channel: `closed-uae`

---

## Table of contents
1. [Beta Operations Report](#1-beta-operations-report)
2. [Beta Success Metrics](#2-beta-success-metrics)
3. [Feedback System Report](#3-feedback-system-report)
4. [Remote Configuration Report](#4-remote-configuration-report)
5. [Security Completion Report](#5-security-completion-report)
6. [Launch Recommendation](#6-launch-recommendation)

---

## 1. Beta Operations Report

### Distribution channels

| Channel | Status | Notes |
|---|---|---|
| Google Play Internal Testing | Ready | Upload `app-release.aab` (build 22); add tester emails |
| Google Play Closed Testing | Ready | Track: `closed-uae`; staged rollout 10% → 50% |
| Apple TestFlight | Config pending | `ios/Runner/` exists; requires Apple Developer account + codesign |
| Version naming | `2.2.0` | Marketing version |
| Build numbering | `22` | Monotonic; see `docs/release/VERSIONING.md` |
| Release channel | `closed-uae` | `AppConfig.betaChannel` |

### Android setup (before first upload)
1. Change `applicationId` from `com.example.rihla` to production ID (e.g. `com.rihla.app`).
2. Configure release signing (currently debug-signed).
3. Upload AAB to Internal → promote to Closed after smoke test.

### TestFlight setup
1. Create App Store Connect record matching bundle ID.
2. Archive with `flutter build ipa` on macOS with distribution cert.
3. Upload via Transporter; add internal + external tester groups.

### In-app beta entry points
- **Cloud & Account** → “Send beta feedback” → `/beta/feedback`
- Deep link: `/beta/feedback?type=routing_issue` (and other `BetaFeedbackType.wireName` values)

### Operational checklists
- `docs/beta/BETA_ROLLOUT_CHECKLIST.md`
- `docs/beta/DAILY_MONITORING_CHECKLIST.md`
- `docs/beta/ISSUE_TRIAGE_WORKFLOW.md`
- `docs/beta/WEEKLY_BETA_REPORT_TEMPLATE.md`

### Real-device test matrix (execute during beta)
| Scenario | Priority |
|---|---|
| Long-distance journey (Dubai ↔ Abu Dhabi) | P0 |
| Underground parking GPS recovery | P0 |
| Tunnel transitions | P0 |
| Offline ↔ online switching | P0 |
| Low battery / background navigation | P1 |
| Phone call interruption | P1 |
| Bluetooth audio interruption | P1 |
| Android Auto readiness | Assessment only — not integrated |
| Apple CarPlay readiness | Assessment only — not integrated |

---

## 2. Beta Success Metrics

### Launch targets (closed beta exit criteria)

| Metric | Target | Measurement |
|---|---|---|
| Crash-free sessions | ≥ **99.0%** | Crashlytics + on-device `BetaMetricsService` |
| Journey completion rate | ≥ **85%** | `journeys_completed / journeys_started` |
| Navigation success | ≥ **90%** | `1 - navigation_cancel_rate` |
| Cloud sync success | ≥ **95%** | `cloud_sync_ok / (ok + fail)` |
| Emergency reliability | ≥ **99%** SOS queue drain within 24h | Manual + analytics |
| AI response success | ≥ **90%** | AI sessions without error state |
| Average app rating | ≥ **4.2 / 5** | Play Console / TestFlight feedback |
| Battery (navigation) | ≤ **8%/hour** mid-range Android | On-device profiling during beta |

### Dashboard counters (`BetaMetricsService.dailySnapshot()`)
- DAU sessions, WAU sessions (weekly key)
- Journey started / completed / cancel rate
- Crash-free session rate
- AI, emergency, offline download, explore usage
- Cloud sync success / failure
- Search success / failure

Export: `ref.read(betaMetricsServiceProvider).exportJson()` for weekly report.

---

## 3. Feedback System Report

### Architecture (`lib/features/beta_feedback/`)

| Layer | Component |
|---|---|
| Domain | `BetaFeedback`, `BetaFeedbackType`, `SupportBundle`, `BetaFeedbackRepository`, `BetaFeedbackService`, `BetaFeedbackState` |
| Data | `BetaFeedbackLocalDatasource`, `BetaFeedbackRepositoryImpl`, `BetaFeedbackServiceImpl`, `SupportBundleGenerator`, `BetaMetricsService` |
| Presentation | `BetaFeedbackController`, `BetaFeedbackPage`, `BetaFeedbackCoordinator` |

### Supported feedback types
Bug report, feature request, journey feedback (with 1–5 star rating), routing issue, place issue, map correction, speed camera issue, Salik issue, AI feedback, emergency feedback, crash report.

### Diagnostics (user consent required)
`SupportBundleGenerator` produces sanitized bundle:
- App version, build, platform, OS version, device hostname
- Feature flags snapshot (from `RemoteConfig`)
- Sanitized navigation/AI log excerpts (max 20 lines each)
- Crash identifiers (from buffering crash reporter)
- Performance metric keys

**Excluded by default:** medical data, tokens, emails, GPS coordinates (`LogSanitizer`).

### Screenshot attachment
Hook point: `screenshotPath` field on `BetaFeedback` + `BetaFeedbackService.submit()`. UI placeholder ready; capture integration deferred to device QA (requires `RepaintBoundary` / platform picker — not added to avoid new dependencies in this phase).

### Sync
`BetaFeedbackCoordinator` drains pending feedback on connectivity restore (mirrors `AccountSyncCoordinator` pattern).

---

## 4. Remote Configuration Report

### Architecture (`lib/core/remote_config/`)

| Component | Role |
|---|---|
| `RemoteConfig` entity | Feature flags, maintenance mode, kill switches, regional rollout |
| `RemoteConfigLocalDatasource` | Cached overrides in SharedPreferences |
| `RemoteConfigRemoteDatasource` | Fetches JSON from `REMOTE_CONFIG_URL` |
| `RemoteConfigRepositoryImpl` | Merges compile defaults + remote |
| `remoteConfigProvider` | Effective runtime config |
| `aiFeatureEnabledProvider` | AI gate (replaces direct `ApiConfig.aiEnabled` in features) |

### Flags

| Flag | Default | Kill switch key |
|---|---|---|
| `maintenanceMode` | false | — |
| `aiEnabled` | compile + remote AND | `ai` |
| `emergencyEnabled` | true | `emergency` |
| `exploreEnabled` | true | `explore` |
| `offlineEnabled` | true | `offline` |
| `cloudSyncEnabled` | compile | `cloud` |
| `betaFeedbackEnabled` | true | `feedback` |
| `uaeIntelligenceEnabled` | true | `uae` |
| `regionalRollout` | `['AE']` | — |

### Activation
```bash
--dart-define=REMOTE_CONFIG_URL=https://your-cdn/rihla-remote-config.json
```

Fetched on app bootstrap via `remoteConfigControllerProvider.refresh()`.

### Sample remote JSON
```json
{
  "maintenanceMode": false,
  "aiEnabled": true,
  "emergencyEnabled": true,
  "regionalRollout": ["AE"],
  "killSwitches": {},
  "rawVersion": 1
}
```

---

## 5. Security Completion Report

### Completed (Phase 19)

| Item | Status |
|---|---|
| Medical profile encrypted at rest | ✅ `EmergencySecureStorage` (Keychain / EncryptedSharedPreferences) |
| Vehicle profile encrypted at rest | ✅ Same |
| Emergency contacts encrypted at rest | ✅ Same |
| One-time migration from plaintext SharedPreferences | ✅ `EmergencyProfileMigration` |
| Key management | Platform secure storage; test injection via `memoryStore` |
| Diagnostic sanitization | ✅ `LogSanitizer` on all support bundles |
| Migration strategy documented | Below |

### Migration strategy
1. On first read, `EmergencyProfileMigration.migrateIfNeeded()` runs.
2. Reads legacy keys (`emergency_medical_profile`, `emergency_vehicle_profile`, `emergency_contacts`) from SharedPreferences.
3. Writes JSON to secure storage keys (`*_enc`).
4. Deletes legacy plaintext keys.
5. Sets `emergency_secure_migration_v1=true` — idempotent.

### Rollback
If secure storage fails on a device, users re-enter profiles via Emergency settings (data loss only on failed migration — logged as non-fatal).

### Residual
- Incidents/timeline remain in SharedPreferences (operational, lower sensitivity).
- Production `applicationId` and release signing still TODO before store upload.

---

## 6. Launch Recommendation

### **Recommendation: PROCEED with closed UAE beta**

| Dimension | Score | Notes |
|---|---:|---|
| Beta tooling | 9/10 | Feedback, metrics, remote config, diagnostics |
| Security | 9/10 | Medical/vehicle/contacts encrypted; migration tested |
| Observability | 9/10 | Product analytics + beta metrics dashboard |
| Distribution readiness | 7/10 | Android AAB ready; bundle ID + signing + TestFlight pending |
| Stability | 8.5/10 | 280+ tests; encrypted storage migration covered |

### Gating before open beta / GA
1. Production `applicationId` + release signing.
2. Host `remote-config.json` and enable `REMOTE_CONFIG_URL`.
3. Enable Crashlytics + PostHog on beta builds.
4. Complete P0 real-device matrix above.
5. First weekly beta report using `WEEKLY_BETA_REPORT_TEMPLATE.md`.

### Android Auto / CarPlay
**Not integrated.** Assessment: map/navigation architecture is Flutter + MapLibre; CarPlay/Android Auto require native bridge modules — out of scope for closed beta; plan for Phase 20+ if needed.

---

**Wait for approval before Phase 20.**
