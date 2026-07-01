# Rihla Backend — Sprint 2: Live Navigation Platform

## Navigation API (`/api/v1/navigation`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/plan` | Plan journey via live Valhalla (driving/walking/cycling, alternates) |
| POST | `/start` | Start navigation session |
| POST | `/pause` | Pause active session |
| POST | `/resume` | Resume paused session |
| POST | `/end` | End session |
| GET | `/active` | Get active/paused session |
| POST | `/location` | GPS update (rate-limited 120/min) |
| GET | `/progress` | Live progress |
| GET | `/eta` | Live ETA |
| GET | `/history` | GPS points, events, statistics |

## Services

- **JourneyPlannerService** — Valhalla routing + DB persistence
- **NavigationSessionManagerService** — session lifecycle
- **RouteManagerService** — polyline6 decode, route selection
- **GpsTrackingService** — GPS validation, storage, speed/heading
- **EtaEngineService** — remaining distance/time with traffic weighting
- **OffRouteDetectionService** — perpendicular distance threshold
- **ArrivalDetectionService** — destination proximity
- **JourneyRecorderService** — progress + statistics
- **EventEngineService** — JourneyStarted/Paused/Resumed/Ended/OffRoute/Arrival/etc.
- **RealtimeBroadcastService** — Supabase Realtime broadcast (location, progress, eta, status)
- **ValhallaService** — live `/route`, `/trace_route` (snap-to-road), polyline6

## Realtime channels

`navigation:{sessionId}` — events: `location`, `progress`, `eta`, `status`, plus typed navigation events.
