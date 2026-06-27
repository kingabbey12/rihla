# Version 1.1 Roadmap — Rihla

Post-launch priorities, informed by beta learnings and v1.0 known issues. Ordered
by priority; scope confirmed after first weeks of production telemetry.

## P0 — Reliability & operations
- Wire **Firebase Crashlytics + Performance** adapter behind the existing
  `CrashReporter`/observability boundary (resolves OPS-1).
- Production **performance traces**: journey-start latency, route computation,
  cold-start budget verification on real devices.
- Harden **Android background location** against OEM battery optimizers
  (foreground service tuning) (PRD-1).

## P1 — In-car & navigation
- **Android Auto** and **Apple CarPlay** support (assessed in Phase 19) (PRD-4).
- Lane guidance and improved junction/tunnel transitions.
- Smarter rerouting and traffic-aware ETA.

## P2 — UAE intelligence depth
- Expand and freshen Salik/speed-camera/driving-rule data and add user-correction
  pipeline from feedback (PRD-2).
- Parking availability and fuel-price freshness improvements.

## P3 — AI & personalization
- Faster, more reliable AI copilot; on-device summary for common queries; clearer
  confidence/uncertainty signaling (PRD-3).
- Personalized suggestions from saved places (privacy-preserving).

## P4 — Growth & platform
- Branded launcher icon/splash and store creative refresh (OPS-3).
- Localization beyond EN/AR; broader RTL polish.
- Optional widgets / quick actions; share ETA.

## Continuous
- Triage-driven bug fixes from `support/SUPPORT_WORKFLOW.md`.
- Accessibility and performance regression guards.
- Security review cadence; key-management and data-deletion audits.
