# Issue Triage Workflow — Closed Beta

## Severity definitions

| Level | Definition | Response |
|---|---|---|
| P0 | Crash loop, data loss, SOS failure, security breach | Hotfix within 24h |
| P1 | Core flow broken (nav, search, offline) | Fix within 3 days |
| P2 | Degraded UX, wrong data advisory | Next beta build |
| P3 | Cosmetic, nice-to-have | Backlog |

## Triage steps
1. **Intake** — feedback app, Play review, crash report, or tester email
2. **Reproduce** — assign owner; note device, OS, build number
3. **Classify** — P0–P3 using table above
4. **Route** — engineering (bug), product (feature request), ops (distribution)
5. **Fix** — branch from release tag if hotfix; else `main`
6. **Verify** — regression test + device confirmation
7. **Close** — notify tester; update weekly report

## Labels
`beta`, `p0`–`p3`, `navigation`, `emergency`, `ai`, `offline`, `security`, `uae`

## SLA
- P0: acknowledge 2h, fix 24h
- P1: acknowledge 8h, fix 72h
- P2/P3: next sprint planning
