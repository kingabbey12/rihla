# Sprint 5 — Analytics Platform

Production analytics derived from journeys, navigation sessions, GPS points, and app events.

## Services

| Engine | File |
|--------|------|
| Analytics Engine | `analytics-engine.service.ts` |
| Journey Statistics | `journey-statistics-engine.service.ts` |
| Driving Score | `driving-score-engine.service.ts` |
| Achievements | `achievement-engine.service.ts` |
| Vehicle Analytics | `vehicle-analytics.service.ts` |
| Leaderboard | `leaderboard-engine.service.ts` |
| User Intelligence | `user-intelligence-engine.service.ts` |
| Weekly Reports | `weekly-report-engine.service.ts` |
| Monthly Reports | `monthly-report-engine.service.ts` |
| Insights | `insight-engine.service.ts` |
| Events | `analytics-event.service.ts` |
| Cache | `analytics-cache.service.ts` |

## Data Sources

- `journeys`, `navigation_sessions`, `journey_points`, `journey_statistics`
- `search_history`, `ai_conversations`, `sos_requests`, `roadside_requests`
- `saved_places`, `vehicles`

## API (`/api/v1/analytics`)

- `GET /dashboard`
- `GET /journeys`
- `GET /statistics`
- `GET /driving-score`
- `GET /achievements`
- `GET /reports/weekly`
- `GET /reports/monthly`
- `GET /leaderboard?scope=&metric=&friendIds=`

## Verification

```bash
cd backend && npm install && npm test && npx prisma migrate deploy
```
