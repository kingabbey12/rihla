# Phase 13 — Explore Platform Report

**Tag:** `v1.6-explore-platform`  
**Date:** June 2026

## Executive Summary

Phase 13 delivers the complete Explore discovery ecosystem for Rihla — a map-integrated platform for finding fuel, EV chargers, restaurants, services, and attractions around the driver. Explore integrates with Journey, Navigation, Safety, Search, and Offline modules without modifying `NavigationSession` or redesigning the map.

**Production readiness score: 88 / 100** (up from 84 after Phase 12)

---

## 1. Explore Architecture Report

### Module structure

```
lib/features/explore/
  domain/       — entities, repositories, services
  data/         — catalog, clustering, favorites, service impl
  presentation/ — controller, overlays, place sheet, launcher
```

### Core components

| Component | Role |
|-----------|------|
| `ExploreRepository` | Data access facade for search and journey recommendations |
| `ExploreService` | Business logic: filtering, clustering, offline/online aggregation |
| `ExploreController` | Riverpod state machine (`Idle` → `Loading` → `Ready` → `PlaceSelected`) |
| `ExploreCategory` | 17 discovery categories (fuel, EV, restaurants, coffee, hotels, hospitals, pharmacies, police, restrooms, parking, mosques, ATMs, car wash, malls, supermarkets, attractions) |
| `ExplorePlace` | Rich POI model with rating, hours, distance, ETA, fuel/EV/parking metadata |
| `ExploreFilter` | Distance, rating, open now, 24h, EV connector, fuel type, parking, accessible, family friendly |
| `ExploreSearch` | Query + viewport + pagination parameters |
| `ExploreResult` | Paginated discovery results with offline flag |
| `ExploreFavoritesRepository` | Saved, pinned, recent, visited places + collections |

### Integration points

| System | Integration |
|--------|-------------|
| **Map** | `exploreMapMarkersProvider` → `MapView` circle annotations with tap handling |
| **Journey** | Navigate button → `journeyControllerProvider.planToDestination()` |
| **Search** | `selectFromSearch()` bridges `SearchPlace` → Explore place sheet |
| **Fuel / EV / Parking** | Live module data merged into online Explore results |
| **Offline** | `OfflinePoiCatalog` + downloaded regions when `isOfflineModeProvider` is true |
| **Safety / Traffic / Weather** | Journey recommendation inputs from journey metrics and live journey state |

### Routing

`/explore` → `ExploreLauncherPage` activates Explore and redirects to `/maps` with overlay active.

---

## 2. Offline Explore Report

| Capability | Status |
|------------|--------|
| Offline POI source | `OfflinePoiCatalog.poisForRegion()` via `OfflineRepository.getDownloadedRegions()` |
| Offline detection | `isOfflineModeProvider` gates online live-module calls |
| Fallback | Seed catalog when no regions downloaded |
| No internet required | Yes, for downloaded UAE regions |
| Offline flag in results | `ExploreResult.isOffline` |

When offline, Explore skips Fuel/EV/Parking live API calls and serves POIs from installed offline regions. Search and route facades (Phase 12) remain unchanged.

---

## 3. Journey Recommendation Report

`exploreJourneyRecommendationsProvider` watches active journey preview and live navigation state.

### Recommendation triggers

| Condition | Recommendation |
|-----------|----------------|
| Fuel < 25% | Nearby fuel stations |
| Battery < 20% | EV charging stops |
| Duration > 90 min or heavy traffic | Coffee breaks |
| Long trip or adverse weather | Restaurants |
| Heavy traffic | Rest areas / parking |

### Inputs

- `JourneyMetrics` (fuel estimate, battery estimate, duration, traffic, weather)
- `LiveJourneyActive` state during navigation
- Map camera position for proximity search

Recommendations display as a banner in `ExploreMapOverlay` when a journey is active.

---

## 4. Performance Report

| Technique | Implementation |
|-----------|----------------|
| Marker clustering | `ExploreMarkerClusterer` — grid-based buckets by zoom level |
| Lazy loading | Paginated `ExploreSearch` with `page` / `pageSize` (default 50) |
| Image cache | `Image.network` with `cacheWidth: 800` in place sheet |
| Viewport loading | `viewportNorth/South/East/West` filter in search |
| Map rendering | Batch `addCircles` / `clearCircles` on marker provider changes |
| Cluster tap | Zoom-in animation (+2 levels) |

At zoom ≥ 15, markers render individually. At zoom ≤ 10, nearby places cluster into count bubbles.

---

## 5. Remaining Production Gaps

| Gap | Priority | Notes |
|-----|----------|-------|
| Live Overpass/OSM Explore API | High | Currently uses seed catalog + fuel/EV/parking modules |
| Symbol labels for cluster counts | Medium | Circles only; no numeric cluster labels yet |
| Collections UI | Medium | Data layer complete; no collections management screen |
| Real place photos | Medium | Placeholder URLs; needs photo API |
| Explore search bar | Low | Uses global `MapSearchBar`; dedicated Explore query UI optional |
| AI-powered suggestions | Deferred | `ApiConfig.aiEnabled = false` — awaiting Phase 14+ approval |
| Global region catalog | Low | UAE-focused seed data; offline regions from Phase 12 |
| Marker animation transitions | Low | Instant circle swap; smooth fade not yet implemented |

---

## 6. Updated Production Readiness Score

| Area | Phase 12 | Phase 13 | Delta |
|------|----------|----------|-------|
| Architecture | 90 | 91 | +1 |
| Discovery / Explore | 40 | 85 | +45 |
| Map integration | 80 | 86 | +6 |
| Offline capability | 88 | 90 | +2 |
| Journey integration | 82 | 88 | +6 |
| Test coverage | 85 | 87 | +2 |
| Live data depth | 75 | 76 | +1 |

**Overall: 88 / 100**

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | Pass (no errors) |
| `flutter test` | **188 tests** pass |
| `flutter build apk --release` | Success |

---

## Test coverage (Phase 13)

`test/features/explore/explore_platform_test.dart` — 8 tests:

- Marker clustering (low/high zoom)
- Filter matching and search pagination
- Offline Explore with downloaded regions
- Favorites (save, pin, visit)
- Journey recommendations (fuel + coffee)
- Search → Explore place selection

---

*Awaiting approval before Phase 14.*
