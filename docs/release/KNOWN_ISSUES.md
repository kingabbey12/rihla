# Known Issues — Rihla v1.0.0

Status at launch. None are Critical or High-severity (blocking) for release.

## Operational / configuration (must be completed by ops before/at GA)
| ID | Item | Severity | Notes |
| --- | --- | --- | --- |
| OPS-1 | Firebase Crashlytics/Performance adapter not yet wired | Medium | Boundary is ready (`CrashReporter`); `BufferingCrashReporter` used until the Firebase adapter + `google-services.json`/`GoogleService-Info.plist` are added. On-device crash-free tracking active meanwhile. |
| OPS-2 | Production secrets injected at build time | Medium | `DART_DEFINES` (PostHog, Supabase, remote config URL, cert pins) must be set in the release pipeline; placeholders documented in `PRODUCTION_CONFIG.md`. |
| OPS-3 | Launcher icon / splash not yet branded | Low | Still using Flutter defaults; add `flutter_launcher_icons`/`flutter_native_splash` assets before store screenshots. |
| OPS-4 | Status page + escalation names | Low | Host status page and fill `ESCALATION_CONTACTS.md`. |

## Product (tracked, non-blocking)
| ID | Item | Severity | Workaround |
| --- | --- | --- | --- |
| PRD-1 | Background location killed by aggressive battery optimizers on some Android OEMs | Medium | KB guidance to whitelist Rihla; revisit foreground-service tuning in v1.1. |
| PRD-2 | UAE Salik/camera advisory data completeness depends on third-party sources | Medium | Clearly marked advisory-only; in-app reporting via feedback. |
| PRD-3 | AI copilot answers can be inaccurate | Medium | Disclaimers in app/Terms; remote kill switch available. |
| PRD-4 | Android Auto / Apple CarPlay not yet supported | Low | Assessed in Phase 19; planned for v1.1 (see roadmap). |
| PRD-5 | iOS release requires manual signing/team setup in Xcode | Low | Documented in `PRODUCTION_CONFIG.md`. |

## Severity key
Critical = app unusable/safety · High = major feature broken, no workaround ·
Medium = workaround exists · Low = cosmetic/minor.
