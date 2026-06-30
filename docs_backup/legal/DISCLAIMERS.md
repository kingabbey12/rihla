# Disclaimers & Permission Copy

Reusable strings for in-app disclaimers, store metadata, and OS permission prompts.

---

## AI disclaimer
> Rihla's AI copilot provides automated suggestions that may be inaccurate or incomplete. It is not professional advice. Always verify important information and use your own judgment, especially while driving.

## Emergency disclaimer
> Rihla's emergency features are an assistance aid and not a replacement for official emergency services. In an emergency, call local services immediately — UAE: 999 (Police), 998 (Ambulance), 997 (Civil Defence). Availability of emergency features depends on your device, connectivity, and permissions.

## Medical information disclaimer
> The medical profile is stored to help you share information with responders. It is not medical advice and is not monitored by medical professionals. Keep it accurate and up to date. You can edit or delete it at any time.

## Navigation / driving advisory disclaimer
> Maps, routes, traffic, Salik, speed-camera, and driving-rule information are advisory and may be inaccurate or outdated. Rihla never encourages speeding or unsafe or illegal driving. Always follow real-world signs, signals, and laws.

---

## OS permission usage strings

### iOS (`Info.plist`)
- `NSLocationWhenInUseUsageDescription`
  > Rihla uses your location to show your position, calculate routes, and provide navigation and safety advisories while you use the app.
- `NSLocationAlwaysAndWhenInUseUsageDescription` (only if background location is later required)
  > Rihla uses your location during active navigation to keep guidance accurate.
- `NSMotionUsageDescription` (if motion used)
  > Used to improve navigation accuracy.

### Android (`AndroidManifest.xml`)
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
  > Location is required for navigation, routing, and nearby search.
- `INTERNET` / `ACCESS_NETWORK_STATE`
  > Required to fetch maps, routes, and live data; the app also supports offline use.

### In-app location rationale (pre-permission prompt)
> To navigate and show what's around you, Rihla needs access to your location. You can change this anytime in settings.
