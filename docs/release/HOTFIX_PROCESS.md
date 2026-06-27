# Hotfix Process

For urgent fixes to a live release (P0/P1) that cannot wait for the next planned release.

## 1. Branch
- [ ] Branch from the **released tag**, not `main` (avoids shipping unrelated in-flight work):
  ```bash
  git checkout -b hotfix/x.y.z+1 vX.Y-<name>
  ```

## 2. Fix
- [ ] Make the **smallest possible** change addressing the incident.
- [ ] Add a regression test that fails without the fix.
- [ ] Bump PATCH and the build number in `pubspec.yaml`.

## 3. Verify (fast lane)
- [ ] `flutter analyze` — 0 errors.
- [ ] `flutter test` — all pass.
- [ ] Targeted manual smoke test of the affected flow.
- [ ] `flutter build appbundle` + `flutter build ios --release`.

## 4. Ship
- [ ] Submit (expedited review on Apple if warranted).
- [ ] Staged rollout but accelerated; monitor crash-free rate closely.
- [ ] Tag: `vX.Y.(Z+1)-hotfix`.

## 5. Back-merge
- [ ] Merge the hotfix branch back into `main` so the fix is not lost in the next release.
- [ ] Confirm the regression test is present on `main`.

## 6. Record
- [ ] Update the incident log with root cause and prevention follow-ups.
