# Versioning Strategy

## Scheme
Rihla uses **Semantic Versioning** for the marketing version plus a monotonic build number:

```
pubspec.yaml → version: MAJOR.MINOR.PATCH+BUILD
```

- **MAJOR** — breaking changes / major platform milestones.
- **MINOR** — new capabilities or a completed phase (backward compatible).
- **PATCH** — bug fixes and hardening with no behavior change for users.
- **BUILD** — integer that **always increases** (required by both stores). Never reused.

Current: **2.1.0+21**

## Phase → version mapping
Each delivered phase maps to a minor bump and a git tag:
- `v2.0-uae-intelligence` → 2.0.0
- `v2.1-production-hardening` → 2.1.0

## Build number policy
- Build number = `MAJOR*10000 + MINOR*100 + PATCH*?` is **not** required; simplest is a globally incrementing integer.
- CI owns the build number; never decrement.

## Tags
- Annotated git tag per release: `vMAJOR.MINOR-<short-name>`.
- Tag the exact commit that produced the store binaries.

## Branching
- `main` is always releasable.
- Release work merges to `main`; tag from `main`.
- Hotfixes: see `HOTFIX_PROCESS.md`.
