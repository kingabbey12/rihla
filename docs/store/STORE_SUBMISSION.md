# Store Submission — Rihla v1.0.0

Companion to `STORE_LISTING.md`. Covers Google Play and Apple App Store
submission specifics for the v1.0.0 public launch.

## Shared listing copy

**App name:** Rihla — UAE Navigation

**Subtitle / short description (≤80 / ≤30 chars):**
> Offline UAE maps, safety alerts & SOS

**Keywords:** uae navigation, dubai maps, abu dhabi, offline maps, salik,
speed camera, gps, emergency sos, road safety, ai copilot, gulf, emirates

**Promo / full description:** see `STORE_LISTING.md`.

**Support URL:** https://rihla.app/support · **Marketing URL:** https://rihla.app
**Privacy policy URL:** https://rihla.app/privacy
**Support email:** support@rihla.app

## Release notes (v1.0.0)

> Welcome to Rihla 1.0 — navigation built for the UAE.
> • Offline-ready maps and turn-by-turn navigation
> • Salik, speed-camera and driving-rule advisories
> • Emergency SOS with medical profile & contacts
> • AI copilot for your journey
> • Explore fuel, parking and charging nearby
> • English & Arabic with full RTL support

## Google Play

| Field | Value |
| --- | --- |
| Package name | `com.rihla.app` |
| Format | Signed AAB (Play App Signing enrolled) |
| Default language | English (en-US); add Arabic (ar) |
| Category | Maps & Navigation |
| Content rating | Complete IARC questionnaire → expected **Everyone / PEGI 3** |
| Target audience | 18+ (location + emergency features) |

**Data safety form** (matches Privacy Policy):
- Location (precise): app functionality, navigation. Not shared. Optional cloud sync if signed in.
- Personal info (medical/contacts): stored on device, encrypted; only synced with account.
- Analytics/crash: optional, off by default, sanitized; collected only when enabled.
- No data sold. No advertising.

**Permissions justification:**
- `ACCESS_BACKGROUND_LOCATION` — continue turn-by-turn navigation in background.
- `CAMERA` / `RECORD_AUDIO` — accident/emergency documentation and voice commands.
- `POST_NOTIFICATIONS` — navigation and safety alerts.

**Required assets:** feature graphic (1024×500), phone screenshots (≥2, up to 8),
7" & 10" tablet screenshots (optional), 512×512 hi-res icon. See screenshot plan below.

**Rollout:** Internal → Closed → Open testing already exercised in Phase 19.
Launch as **staged production rollout** (start 10–20%).

## Apple App Store

| Field | Value |
| --- | --- |
| Bundle ID | `com.rihla.app` |
| Format | iOS archive / IPA via App Store Connect |
| Primary category | Navigation |
| Age rating | 4+ (verify questionnaire) |
| Price | Free |

**Privacy nutrition labels:**
- Data Linked to You: none by default (only with account: identifiers for sync).
- Data Not Linked to You: optional diagnostics/usage when enabled (sanitized).
- Location used for app functionality; not for tracking.

**App Review notes:** explain background location (navigation), emergency SOS as a
convenience aid (not a substitute for 999/998/997), and the AI advisory disclaimer.
Provide a demo account if cloud sync is reviewed.

**Required assets:** 6.7" and 6.1" iPhone screenshots, optional iPad 12.9";
1024×1024 marketing icon.

## Screenshot plan (both stores)

1. Map + live navigation with a UAE route
2. Offline download screen
3. UAE safety advisories (Salik / camera awareness)
4. Emergency SOS / medical profile
5. AI copilot conversation
6. Explore (fuel / parking / charging)
7. Arabic / RTL home (localization proof)

## Pre-submission checklist
- [ ] App ID `com.rihla.app` on both platforms.
- [ ] Signed AAB and iOS archive produced by the release pipeline.
- [ ] Privacy policy + support URLs live.
- [ ] Data safety / privacy labels match Privacy Policy.
- [ ] Content/age ratings completed.
- [ ] Screenshots (en + ar) uploaded.
- [ ] Release notes added.
- [ ] Demo account provided to Apple review (if needed).
