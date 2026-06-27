# Daily Monitoring Checklist — Closed Beta

Run every morning during the first 2 weeks of beta.

## Crash & stability
- [ ] Crash-free sessions ≥ 99% (Crashlytics / Play Vitals)
- [ ] Review new non-fatal errors; triage P0/P1
- [ ] Check `BetaMetricsService` daily snapshot for anomaly spikes

## Core funnels
- [ ] Journey completion rate vs target (85%)
- [ ] Navigation cancellation rate
- [ ] Search success vs failure ratio
- [ ] Cloud sync success rate

## Feature usage
- [ ] AI usage count + error rate
- [ ] Emergency activations (verify test vs real)
- [ ] Offline downloads started/completed
- [ ] Explore category usage

## Feedback
- [ ] Review new in-app beta feedback submissions
- [ ] Check Play Console / TestFlight reviews
- [ ] Triage issues per `ISSUE_TRIAGE_WORKFLOW.md`

## Remote config
- [ ] Confirm `REMOTE_CONFIG_URL` reachable
- [ ] No unintended kill switches active
- [ ] Maintenance mode off

## Actions
- [ ] Log blockers in issue tracker
- [ ] Hotfix if P0 (see `docs/release/HOTFIX_PROCESS.md`)
- [ ] Update `#beta-ops` channel with status
