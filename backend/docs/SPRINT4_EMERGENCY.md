# Sprint 4 — Emergency Platform

Production emergency backend: SOS, roadside, incidents, live location, encrypted profiles, FCM notifications, Supabase Realtime dispatch.

## Services

| Service | Path |
|---------|------|
| Emergency Service | `emergency.service.ts` |
| SOS Service | `services/sos.service.ts` |
| Roadside Service | `services/roadside.service.ts` |
| Emergency Contact Service | `services/emergency-contact.service.ts` |
| Incident Reporting | `services/incident-reporting.service.ts` |
| Medical Profile | `services/medical-profile.service.ts` |
| Vehicle Profile | `services/vehicle-profile.service.ts` |
| Live Location Share | `services/live-location.service.ts` |
| Realtime Dispatcher | `services/realtime-dispatcher.service.ts` |
| Notification / FCM | `modules/notifications/` |
| Encryption | `shared/crypto/` |

## Security

- AES-256-GCM encryption for medical data and emergency contacts (`ENCRYPTION_KEY`)
- HMAC-signed share tokens with expiry (`SHARE_TOKEN_SECRET`)
- Share token stored as SHA-256 hash only
- Authenticated endpoints + SOS rate limit (5/min)

## Realtime Channels

- `emergency:sos:{id}` — SOS status
- `emergency:roadside:{id}` — roadside updates
- `emergency:location:{id}` — live location
- `emergency:incident:{id}` — incident updates

## Verification

```bash
cd backend && npm install && npm test && npx prisma migrate deploy
docker compose -f docker/docker-compose.yml up --build
```

Set `FIREBASE_SERVER_KEY`, `ENCRYPTION_KEY`, and Supabase keys for full production behavior.
