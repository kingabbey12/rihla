# Support Workflow — Rihla

## Channels
- **Primary:** support@rihla.app
- **Privacy requests:** privacy@rihla.app
- **Security reports:** security@rihla.app
- **In-app:** Settings → Send beta feedback (attaches sanitized diagnostics with consent)
- **Public:** https://rihla.app/support, https://rihla.app/faq

## SLA targets
| Severity | First response | Resolution target |
| --- | --- | --- |
| S1 — Critical (app unusable / safety) | 4 hours | 24 hours (hotfix) |
| S2 — High (major feature broken) | 1 business day | 3 business days |
| S3 — Medium (minor/workaround exists) | 2 business days | next release |
| S4 — Low (cosmetic / request) | 3 business days | backlog |

## Flow
1. **Triage** — label, assign severity, deduplicate. Acknowledge the user.
2. **Reproduce** — request app version, device/OS, steps; check diagnostic bundle.
3. **Classify** — bug → tracker; question → KB answer; request → roadmap backlog.
4. **Resolve** — link to fix/release; for S1/S2 follow `release/HOTFIX_PROCESS.md`.
5. **Close** — confirm with user; add a KB entry if recurring.

## Escalation
Bug reproducible & severe → engineering on-call (see `operations/ESCALATION_CONTACTS.md`).
Possible incident (widespread) → open incident per `operations/INCIDENT_RESPONSE.md`.

## Issue labels
`type:bug` · `type:feature` · `type:question` · `type:crash` ·
`area:navigation` · `area:map` · `area:offline` · `area:emergency` ·
`area:ai` · `area:cloud` · `area:uae` · `area:account` ·
`sev:S1` · `sev:S2` · `sev:S3` · `sev:S4` ·
`needs-info` · `confirmed` · `wontfix` · `duplicate` · `good-first-issue`

## Bug triage cadence
Daily triage of new `type:bug`/`type:crash`; weekly backlog grooming feeding the
v1.1 roadmap.
