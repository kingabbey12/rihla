# Production Operations — Rihla v1.0.0

## Dashboards

| Dashboard | Source | Key panels |
| --- | --- | --- |
| Health | Crash backend + PostHog | Crash-free sessions, crash-free users, ANR rate, error trend |
| Engagement | PostHog | DAU/WAU, retention (D1/D7/D30), session length |
| Journeys | PostHog (`AnalyticsEvent`) | journeyStarted, journeyCompleted, completion rate, cancellation rate |
| Feature usage | PostHog | AI, emergency, offline download, explore usage |
| Reliability | Backend providers | API error/latency for routing, search, weather, Supabase sync success |
| Release | Play Console / App Store Connect | Adoption by version, rollout %, store ratings |

## Alert thresholds

| Metric | Warning | Critical (page) |
| --- | --- | --- |
| Crash-free sessions | < 99.0% | < 98.0% |
| Crash-free users | < 99.0% | < 97.5% |
| Journey completion rate | < 85% | < 75% |
| Cloud sync success | < 98% | < 95% |
| Routing API error rate | > 2% | > 5% |
| Routing p95 latency | > 2.5s | > 5s |
| Emergency SOS failure | any sustained | > 0.5% |
| App rating (rolling 7d) | < 4.0 | < 3.5 |

Emergency SOS failures and crash-free dropping below critical always page on-call.

## Status page
- Public status at https://status.rihla.app (hosted, e.g. Instatus/Statuspage).
- Components: App, Cloud Sync, Routing, Search/Places, Maps/Tiles, AI, Weather.
- Post updates within 30 min of a confirmed S1/S2 incident; post-mortem within 5
  business days.

## Kill switches & remote mitigation
Use remote config (`RemoteConfig`) to mitigate without an app update:
- `maintenanceMode` — show maintenance state during provider outages.
- `aiEnabled` / `emergencyEnabled` — disable a misbehaving subsystem.
- `killSwitches` — disable specific features by key.
- `regionalRollout` — scope a feature/region.

## Routine operations
- **Daily:** review Health + Release dashboards; triage new crashes; check alerts.
- **Weekly:** retention + engagement review; rating review; roadmap grooming.
- **Per release:** follow `release/RELEASE_CHECKLIST.md`; staged rollout; monitor
  the new version's crash-free before widening.

## Backups & data
- Cloud data lives in Supabase; rely on provider PITR/backups. Verify restore
  quarterly. Document data-deletion handling for privacy requests.
