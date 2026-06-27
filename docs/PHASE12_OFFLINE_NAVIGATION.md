# Phase 12 — Offline Navigation Platform Report

**Tag:** `v1.5-offline-navigation`  
**Date:** June 2026

## Executive Summary

Phase 12 transforms Rihla into an offline-capable navigation application with automatic online/offline transitions. Offline capability is injected behind existing `SearchRepository` and `RouteRepository` interfaces — no changes to `NavigationSession`, Journey Engine, Safety Engine, or AI architecture.

**Production readiness score: 84 / 100** (up from 78 after Phase 11)

---

## 1. Offline Architecture Report

### Module structure

```
lib/features/offline/
  domain/     — entities, models, repositories, services
  data/       — engine, storage, sync, POI catalog, UAE regions
  presentation/ — controller, coordinator, bootstrap, Offline Center
```

### Injection pattern

| Interface | Online impl | Offline impl | Facade |
|-----------|-------------|--------------|--------|
| `SearchRepository` | `SearchRepositoryImpl` + Nominatim | `OfflineSearchRepository` | `OfflineAwareSearchRepository` |
| `RouteRepository` | `RouteRepositoryImpl` + Valhalla | `OfflineRouteRepository` | `OfflineAwareRouteRepository` |

### Offline engine states

`Online` · `Offline` · `Syncing` · `Downloading` · `Updating` · `Paused` · `Error`

Observed via `offlineEngineStateProvider` and `isOfflineModeProvider`.

### Automatic transitions

- `ConnectivityNetworkMonitor` detects connect / disconnect / restore
- `OfflineCoordinator` updates state, triggers sync on restore
- No manual mode switching required
- Subtle offline banner when disconnected with downloaded maps

---

## 2. Download Manager Report

| Capability | Status |
|------------|--------|
| Download | Chunked incremental (256 KB chunks) |
| Pause / Resume | Yes |
| Cancel | Yes |
| Delete | Yes |
| Retry | Yes |
| Repair | Rebuilds manifest + POI + routing + checksum |
| Integrity verify | SHA-style checksum per region |
| Version check | Catalog vs installed version |
| Background queue | Timer-driven tick (500 ms) |
| Concurrent downloads | Max 2 simultaneous |

### UAE regions

Abu Dhabi · Dubai · Sharjah · Ajman · Ras Al Khaimah · Fujairah · Umm Al Quwain

Custom region and draw-area hooks reserved for future global expansion.

---

## 3. Storage Report

| Metric | Implementation |
|--------|----------------|
| Root path | `{documents}/rihla_offline/{regionId}/` |
| Files per region | `manifest.json`, `pois.json`, `routing.json`, `checksum.sha256` |
| Storage UI | Total / used / free / offline usage in Offline Center |
| Corruption detection | Missing files or checksum mismatch |
| Outdated detection | Installed version < catalog version |
| Test injection | `OfflineStorageDatasource(testRoot:)` |

---

## 4. Offline Performance Report

| Metric | Value |
|--------|-------|
| Download chunk size | 256 KB |
| Max concurrent downloads | 2 |
| POI search | In-memory index from local JSON |
| Route calculation | Local haversine + profile factors (no network) |
| Memory | POI/routing loaded per-query, not held in RAM |
| Battery | Download tick only when active jobs exist |
| Tests | 11 offline + 169 total passing |

---

## 5. Remaining Online Dependencies

| Feature | Offline behaviour |
|---------|-------------------|
| Weather | Cached if previously fetched; unavailable offline |
| Traffic | Heuristic / last-known; no live TomTom offline |
| Hazards (Overpass) | Session-based + cached; reduced offline |
| AI Copilot | Disabled (`ApiConfig.aiEnabled = false`) |
| Voice TTS | Works offline (on-device TTS when configured) |
| Map tiles (MapLibre) | Requires pre-downloaded region data for full tile offline |
| Fuel / EV / Parking | Online only; graceful empty state offline |
| Nominatim geocoding | Falls back to offline POI index |

---

## 6. Navigation Continuity

When offline with downloaded regions:

- GPS / turn-by-turn via existing `NavigationSession` (unchanged)
- Journey Dashboard via `LiveJourneyMetricsEngine` (offline metrics)
- Safety Dashboard via `LiveSafetyService` (session heuristics)
- Route recalculation via `OfflineRouteService` + `ValhallaRerouteService` fallback
- Journey continuation preserved through `DrivingSessionCoordinator`

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | Pass (warnings only) |
| `flutter test` | 180 passed |
| `flutter build apk --release` | Built |
