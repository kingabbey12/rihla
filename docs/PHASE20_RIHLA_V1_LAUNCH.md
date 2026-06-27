# Phase 20 — Rihla v1.0 Launch

_Version 1.0.0 (build 100) · 27 June 2026 · End of the development roadmap._

This phase prepared and released the first production version of Rihla. **No new
application features were developed** — work was limited to release preparation,
configuration, monitoring, operations, documentation, and launch assets.

---

## Deliverable 1 — Final Release Report

### Scope delivered
| Area | What changed |
| --- | --- |
| Identity | App ID set to `com.rihla.app` (Android namespace/applicationId + iOS bundle id across all configs); Android label → `Rihla`; web/manifest metadata branded. |
| Versioning | `pubspec.yaml` → `1.0.0+100`; `AppConfig` mirrors `1.0.0`/`100` and adds `releaseChannel` (default `production`). Build 100 stays above beta codes. |
| Release signing | `build.gradle.kts` loads `android/key.properties` and signs release with the upload keystore (debug fallback when absent); `key.properties.example` added; Play App Signing documented. iOS signing documented. |
| Minification | R8 `isMinifyEnabled` + `isShrinkResources` with keep rules (`proguard-rules.pro`). |
| Secrets hygiene | `.gitignore` now excludes keystores, `key.properties`, `*.p8/.p12`, `.env*`, `google-services.json`, `GoogleService-Info.plist`. |
| Production config | `docs/release/PRODUCTION_CONFIG.md` — IDs, environment, `--dart-define` secrets, signing, minification. |

### Release artifacts
- Signed **AAB** + **APK** via the `Release` GitHub Actions workflow (tag `v*`).
- **iOS archive** job (requires Apple signing setup).

### Final audit results
See "Phase 20 — Final Audit" section at the end of this report.

### Sign-off
Code, configuration, and documentation for v1.0.0 are complete. Remaining items
to flip on are operational (see Known Issues OPS-1..4) and do not block tagging.

---

## Deliverable 2 — Launch Report

### Distribution
- **Google Play:** signed AAB, package `com.rihla.app`, staged production rollout
  (start 10–20%), Internal→Closed→Open tracks already exercised in Phase 19.
- **Apple App Store:** iOS archive, bundle `com.rihla.app`, TestFlight validated
  in beta.
- Submission specifics, listing copy, privacy labels, content rating, screenshots,
  and release notes: `docs/store/STORE_SUBMISSION.md` + `STORE_LISTING.md`.

### Launch assets
- Marketing **website** (`website/`): landing, Privacy, Terms, Support/Contact, FAQ.
- **Release notes** (`docs/release/RELEASE_NOTES_v1.0.0.md`).
- Legal: Privacy Policy & Terms finalized with real contact + UAE governing law.

### Launch metrics & targets
Tracked from day one via PostHog + crash backend + store consoles. Full set and
targets in `docs/operations/LAUNCH_METRICS.md`. Headline v1.0 targets:
crash-free sessions ≥ 99.5%, journey completion ≥ 85%, store rating ≥ 4.3,
D7 retention ≥ 20%, cloud sync ≥ 98%, emergency reliability ≥ 99%.

### Go-live sequence
1. Tag `v1.0.0` → `Release` workflow builds signed artifacts.
2. Upload AAB (Play) + IPA (App Store) with assets and notes.
3. Submit for review; address review notes (background location, SOS, AI advisory).
4. Staged rollout; monitor new-version crash-free before widening.

---

## Deliverable 3 — Production Operations Report

Operational readiness is documented under `docs/operations/`:
- **Dashboards** — Health, Engagement, Journeys, Feature usage, Reliability,
  Release (`PRODUCTION_OPERATIONS.md`).
- **Alert thresholds** — crash-free, completion, sync, routing error/latency,
  emergency failure, rating — with warning/critical paging levels.
- **Incident response** — severities, roles (IC/Eng/Comms), mitigate-first via
  remote-config kill switches / rollback, post-mortems (`INCIDENT_RESPONSE.md`).
- **Status page** — components and update SLAs.
- **Escalation contacts** — on-call rotation + vendor contacts
  (`ESCALATION_CONTACTS.md`, names TBD before GA).
- **Monitoring enablement** — Crashlytics, PostHog, Analytics, Performance,
  Remote Config, Feature Flags (`docs/release/MONITORING_SETUP.md`).
- **Support** — workflow, SLAs, issue labels, bug triage, knowledge base
  (`docs/support/`).

Remote mitigation is available without an app update via `RemoteConfig`
(maintenance mode, kill switches, AI/emergency toggles, regional rollout).

---

## Deliverable 4 — Known Issues

Full list in `docs/release/KNOWN_ISSUES.md`. **No Critical or High-severity
(blocking) issues at launch.** Summary:
- **Operational (complete before/at GA):** Firebase crash adapter wiring (OPS-1),
  production secrets injection (OPS-2), branded icon/splash (OPS-3), status
  page + escalation names (OPS-4).
- **Product (tracked, non-blocking):** OEM background-location behavior (PRD-1),
  advisory data completeness (PRD-2), AI accuracy disclaimers (PRD-3), Android
  Auto/CarPlay deferred to v1.1 (PRD-4), iOS manual signing (PRD-5).

---

## Deliverable 5 — Version 1.1 Roadmap

Full roadmap in `docs/release/ROADMAP_V1.1.md`. Priorities:
- **P0 Reliability/ops:** Firebase Crashlytics+Performance adapter; production
  traces; Android background-location hardening.
- **P1 In-car:** Android Auto + Apple CarPlay; lane guidance; smarter rerouting.
- **P2 UAE depth:** fresher Salik/camera/rule data + user-correction pipeline.
- **P3 AI:** faster/more reliable copilot; privacy-preserving personalization.
- **P4 Growth:** branded creative, more localization, widgets/quick actions.

---

## Deliverable 6 — CTO Launch Recommendation

**Recommendation: GO for staged production launch of Rihla v1.0.0.**

Rationale:
- The product completed a full hardening phase (Phase 18) and a real-user closed
  UAE beta (Phase 19): observability, security (encrypted medical/vehicle
  profiles), accessibility, performance, and remote configuration are in place.
- v1.0.0 release engineering is complete: production app IDs, release signing with
  Play App Signing, R8 minification, secret hygiene, signed AAB/APK + iOS archive
  pipeline, and full store/website/legal assets.
- No Critical or High-severity bugs are open. Remaining items are operational
  toggles, not code blockers.

Conditions before flipping to 100%:
1. Wire the Firebase Crashlytics/Performance adapter and confirm crash visibility
   (OPS-1) — or accept on-device crash-free tracking for the initial staged %.
2. Set production `DART_DEFINES` (PostHog, Supabase, remote config URL, cert pins)
   in the release pipeline (OPS-2).
3. Add branded launcher icon/splash and finalize store screenshots (OPS-3).
4. Stand up the status page and fill escalation contacts (OPS-4).

Launch posture: start at 10–20% staged rollout, watch crash-free and journey
completion against thresholds, widen on green. Keep remote kill switches ready.

---

## Phase 20 — Final Audit

Verification commands (run on this build):

| Command | Result |
| --- | --- |
| `flutter analyze` | ✅ exit 0 — no errors (106 pre-existing info/warnings, none introduced) |
| `flutter test` | ✅ 281 tests passed |
| `flutter build apk --release` | ✅ `app-release.apk` (93.0 MB, R8 + tree-shaking) |
| `flutter build appbundle` | ✅ `app-release.aab` (73.2 MB) |

> Build note: pinned Kotlin JVM target to 17 in `android/app/build.gradle.kts` to
> resolve a Java/Kotlin toolchain mismatch exposed by the release build.

Readiness checklist:
- [x] `flutter analyze` clean (no errors)
- [x] `flutter test` passing (281)
- [x] Release APK builds
- [x] Release AAB builds
- [x] No Critical bugs · No High-severity bugs (`KNOWN_ISSUES.md`)
- [x] Crash-free target defined and tracked (`LAUNCH_METRICS.md`)
- [x] Security checklist (Phase 18/19 — encryption, key mgmt, pinning, sanitization)
- [x] Performance checklist (Phase 18 — startup, map/marker rendering, image cache)
- [x] Accessibility checklist (Phase 18 — text scaling, high contrast, touch targets, RTL)
- [x] Store checklist (`STORE_SUBMISSION.md`)
- [x] Launch readiness checklist (`release/RELEASE_CHECKLIST.md`)

---

_End of the Rihla development roadmap._
