# Rollback Checklist

When a release shows a regression (crash spike, broken core flow, data risk).

## Decide
- [ ] Severity confirmed (crash-free drop, P0 flow broken, security/privacy issue).
- [ ] Identify whether the issue is client-only or backend/config.

## If backend/config driven
- [ ] Revert the offending config (`--dart-define`, Supabase rules, feature flag).
- [ ] No new build required — fastest path. Verify the fix in production.

## If client (shipped binary) driven
### Google Play
- [ ] Halt the staged rollout immediately.
- [ ] Resume rollout of the previous known-good release (or roll forward with a hotfix if faster).
- [ ] Play does not support true binary rollback once 100% — keep the last good AAB available to re-publish with a higher version code.

### Apple App Store
- [ ] If phased release: pause the phased rollout.
- [ ] Submit an expedited review for the previous good build or a hotfix.

## Communicate
- [ ] Notify stakeholders + beta testers.
- [ ] Open an incident record: trigger, impact, timeline, root cause, follow-ups.

## Post-mortem
- [ ] Blameless post-mortem within 48 h.
- [ ] Add a regression test that would have caught it.
