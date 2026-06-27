# Incident Response — Rihla

## Severity
| Sev | Definition | Examples |
| --- | --- | --- |
| SEV1 | Widespread outage or safety-impacting failure | Crash-free < 98%, emergency SOS broken, app launch fails |
| SEV2 | Major feature degraded for many users | Routing/search down, cloud sync failing |
| SEV3 | Limited or non-critical degradation | One provider slow, minor feature error |

## Roles
- **Incident Commander (IC):** coordinates, owns comms and decisions.
- **Ops/Engineering lead:** investigates and mitigates.
- **Comms:** updates status page and stakeholders.

## Flow
1. **Detect** — alert, support spike, or store reviews.
2. **Declare** — IC opens an incident channel; set severity.
3. **Mitigate first** — prefer remote-config kill switch / maintenance mode /
   rollback over a code fix (see `release/ROLLBACK_CHECKLIST.md`).
4. **Communicate** — status page within 30 min for SEV1/2; regular updates.
5. **Resolve** — confirm metrics recover; close incident.
6. **Post-mortem** — blameless write-up within 5 business days: timeline, root
   cause, impact, action items with owners.

## Mitigation toolbox
- Remote config kill switch / `maintenanceMode`.
- Halt or roll back staged store rollout (Play) / remove from sale temporarily.
- Provider failover or disable affected integration.
- Expedited hotfix per `release/HOTFIX_PROCESS.md`.

## Communication templates
**Investigating:** "We're investigating reports of <issue> affecting <area>.
Updates shortly."
**Identified:** "We identified the cause of <issue> and are applying a fix."
**Resolved:** "<issue> is resolved as of <time>. A post-mortem will follow."
