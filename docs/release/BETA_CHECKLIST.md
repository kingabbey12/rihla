# Closed Beta Checklist

For TestFlight (iOS) and Google Play Internal/Closed testing.

## Build
- [ ] Beta version tagged (e.g. `2.1.0+21-beta`).
- [ ] Analytics + crash reporting **enabled** so beta produces signal.
- [ ] Debug/test affordances disabled in release mode (debug pages are dev-only routes).

## Tester onboarding
- [ ] Tester list defined; invites sent (TestFlight group / Play closed track).
- [ ] Onboarding note: what to test, how to report, known issues.
- [ ] Feedback channel established (form / email / issue tracker).

## Test matrix (testers should cover)
- [ ] Cold start + first-run flow.
- [ ] Search success and failure (bad query / offline).
- [ ] Plan + start + complete a journey.
- [ ] Cancel navigation mid-route.
- [ ] Offline download, then offline search/route.
- [ ] Offline ↔ online switching during a session.
- [ ] Emergency SOS (test mode), medical profile entry.
- [ ] AI copilot prompt + timeout behavior.
- [ ] Explore browsing.
- [ ] Accessibility: large font, high contrast, screen reader.
- [ ] Interruptions: phone call, background → foreground, GPS loss.

## Exit criteria
- [ ] Crash-free sessions ≥ 99% over the beta window.
- [ ] No open P0/P1 defects.
- [ ] Performance targets met on a mid-range device.
- [ ] Accessibility pass on key screens.
