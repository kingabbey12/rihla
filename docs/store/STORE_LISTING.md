# Store Listing & Assets — Rihla v2.1.0

Everything needed for App Store Connect and Google Play Console submission.

---

## App identity
- **Name:** Rihla
- **Subtitle / short:** Smart navigation for the UAE
- **Category:** Navigation (secondary: Travel)
- **Bundle / Application ID:** `com.rihla.app` (confirm before first submission)
- **Version:** 2.1.0 (build 21)
- **Content rating:** Everyone / 4+ (utility; includes emergency assistance info)

---

## Descriptions

### Short description (Google Play, ≤ 80 chars)
> Offline-ready UAE navigation with safety, emergency help, and an AI copilot.

### Promotional text (Apple, ≤ 170 chars)
> Drive the UAE with confidence: offline maps, live safety alerts, Salik & camera awareness, emergency SOS, and an AI copilot that understands your journey.

### Full description
> **Rihla** is a navigation companion built for driving in the United Arab Emirates.
>
> **Navigate anywhere** — fast routing, turn-by-turn guidance, and clear maps that work even when you lose signal thanks to offline downloads.
>
> **Stay safe** — live safety alerts, hazard awareness, and UAE-specific intelligence including Salik toll awareness, speed-camera and emirate driving-rule advisories, and weather/holiday traffic guidance. All advisory only — Rihla never encourages unsafe or illegal driving.
>
> **Get help fast** — built-in emergency SOS with a medical profile and emergency contacts, designed to share what first responders need.
>
> **Explore** — discover places, fuel, parking, and charging around you.
>
> **AI copilot** — ask about your trip in natural language and get context-aware answers grounded in your route and conditions.
>
> **Private by design** — analytics and crash reporting are opt-in, and sensitive data is protected on your device.
>
> Rihla supports English and Arabic with full right-to-left layout.

---

## Keywords (Apple, 100-char field)
```
uae,dubai,navigation,maps,offline,salik,traffic,route,driving,emergency,sos,gps,abu dhabi,sharjah
```

### ASO keyword themes (Google Play — weave into description)
UAE navigation, Dubai maps offline, Salik toll, speed camera alert, emergency SOS, offline GPS, Abu Dhabi route, driving assistant, AI copilot.

---

## Release notes — v2.1.0
> Production hardening release:
> - Faster, smoother maps and lower memory use.
> - Improved reliability with crash-safe startup.
> - Accessibility: dynamic text scaling, high-contrast theme, screen-reader labels.
> - Stronger privacy and security for your data.
> - Polished for a stable, store-ready experience.

---

## Visual assets

### App icon
- Master: **1024×1024** PNG, no alpha, no rounded corners (stores apply masking).
- Generate per-platform sizes with **`flutter_launcher_icons`**:
  ```yaml
  # add to dev_dependencies, then configure:
  flutter_launcher_icons:
    image_path: "assets/store/icon_master.png"
    android: true
    adaptive_icon_background: "#0D6E6E"
    adaptive_icon_foreground: "assets/store/icon_foreground.png"
    ios: true
    remove_alpha_ios: true
  ```

### Adaptive icon (Android)
- Foreground (safe zone) + background color `#0D6E6E` (brand teal).

### Splash / launch screen
- Generate with **`flutter_native_splash`**:
  ```yaml
  flutter_native_splash:
    color: "#0D6E6E"
    image: "assets/store/splash_logo.png"
    android_12:
      color: "#0D6E6E"
      image: "assets/store/splash_logo.png"
  ```

### Screenshots (shot list)
Capture in both light and high-contrast, English + Arabic:
1. Map with route + turn banner.
2. Search results.
3. Offline download center.
4. Emergency SOS / medical profile (test data).
5. Explore (places/fuel/parking).
6. AI copilot conversation.
7. UAE intelligence settings.

**Dimensions:**
- Google Play phone: 1080×1920 (min 2, max 8); Feature graphic **1024×500**.
- Apple 6.7": 1290×2796; 6.5": 1242×2688; 12.9" iPad (if iPad enabled): 2048×2732.

---

## Privacy labels

### Apple Privacy Nutrition Label
| Data type | Collected | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Precise location | Yes (in-use) | No (default) | No | App functionality (navigation) |
| Health (medical profile) | Yes (on-device) | No | No | Emergency assistance |
| Contacts (emergency) | Yes (user-entered) | No | No | Emergency assistance |
| Identifiers | Only if analytics enabled | Optional | No | Analytics (opt-in) |
| Crash data | Only if enabled | No | No | App functionality |
| Usage data | Only if analytics enabled | No | No | Analytics (opt-in) |

> Default builds collect **nothing**; analytics/crash are opt-in via configuration.

### Google Play Data Safety
- **Location:** collected, not shared, used for app functionality; encrypted in transit.
- **Health & fitness (medical profile):** collected, on-device, for emergency features.
- **Personal info (emergency contacts):** user-entered, on-device.
- **App activity / crash logs:** only when analytics/crash reporting enabled; not sold; encrypted in transit; user can opt out.
- Data deletion: account data removable via account settings (cloud sync); local data cleared on app uninstall.

---

## Version metadata
| Field | Value |
|---|---|
| Marketing version | 2.1.0 |
| Build number | 21 |
| Min Android | as per Flutter default + Crashlytics (API 21+) |
| Min iOS | 12.0+ |
| Supported locales | en, ar (RTL) |
| Privacy Policy URL | (host `docs/legal/PRIVACY_POLICY.md`) |
| Support URL | TBD |
