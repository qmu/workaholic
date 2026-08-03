---
created_at: 2026-08-04T09:05:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
feedback: [20260802140323-throttle-repeat-drive-blocked-notifications-for-the-same-unresolved-condition.md]
---

# Throttle repeat drive-blocked alerts for the same unresolved condition

## Overview

The hourly `[Drive]` routine posts a red "drive blocked/aborted" message to `dev-<repo>` on every tick that fails a precondition — even when the failure is the exact same already-known condition as the previous tick. Measured 2026-08-02〜04: one near-identical red alert per hour for two days for a single root cause (the stale baked-in plugin), with no new information in any repeat. The operator's ask (feedback `20260802140323`, reported as qmu/workaholic#168, recorded via PR #169) is: notify once when a condition first appears, suppress or reduce repeats of the same unresolved condition, and alert again only when the condition **changes** or a cool-down elapses.

The structural constraint: each tick is a fresh cloud container, so no local state survives between ticks. The state that does survive and is already readable by the routine session is the **Slack channel itself** (the routine has the Slack MCP and posts there). The throttle should therefore be a dedupe-by-reading rule in the routine template: before posting a failure, read the channel's recent messages; if the most recent failure post carries the same **failure signature** and is younger than the cool-down, do not post a fresh top-level alert (silence, or at most a thread reply/reaction on the existing alert).

## Policies

- `workaholic:operation` / `policies/monitoring.md` — an alert that repeats without new information trains the operator to ignore alerts; dedupe is part of alerting, not garnish.
- `workaholic:implementation` / `policies/observability.md` — the suppressed repeat must still be observable (the tick's terminal report says it suppressed, and why), so throttling never becomes silent failure.

## Key Files

- `plugins/workaholic/skills/workaholify/routines/drive.md` — the only place the posting behavior is defined (the routine is prompt-driven; there is no notifier script in the cloud path). Add a "failure alert dedupe" rule to the template.
- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` — after the template changes, live routines across repositories will report drift; no code change expected here, but the rollout is "refresh the routines", which `/workaholify` already knows how to confirm one at a time.

## Related History

- Feedback `20260802140323-throttle-repeat-drive-blocked-notifications-for-the-same-unresolved-condition.md` — the immutable ask; deliberately scoped to notification behavior, not the underlying trigger.
- The underlying 2026-08-02〜04 trigger (presence-gated bootstrap fast path) was fixed separately by "Version-gate the web bootstrap fast path" — this ticket is still wanted, because the *next* recurring failure will spam identically until dedupe exists.

## Quality Gate

### Acceptance Criteria

- The drive routine template defines a **failure signature** (e.g. the precondition name plus its one-line reason — stable across ticks, not the whole message body) and instructs: read the channel's recent history before posting a red alert; if the latest red alert has the same signature and is younger than the cool-down (default 24h), post no new top-level alert.
- A **changed** signature always posts immediately, and a resolved-then-recurring condition posts again after the cool-down — the rule suppresses repeats, never first reports.
- A suppressed tick is not silent in its own session output: its terminal reconciliation states that the alert was suppressed as a duplicate and names the signature.
- Slack remains never load-bearing: if history cannot be read, the routine posts (fail-open toward alerting, not toward silence).

### Verification Method

- Template review against the criteria (the routine is prose; there is no hermetic harness for cloud sessions).
- One live observation window after the routines are refreshed: induce or wait for a repeated failure and confirm the second tick suppresses while the session log names the suppression.

### Gate

The template states signature, cool-down, fail-open, and the suppression-visibility rule; `/workaholify`'s drift survey shows the live drive routines refreshed to the new template.

## Implementation Steps

1. Add a "Failure alerts are deduped" subsection to `routines/drive.md` §0/§6: define the signature, the read-before-post rule, the 24h cool-down, the fail-open clause, and the requirement to name a suppression in the terminal report.
2. Keep the orange (start), green (PR), yellow (handoff), purple (merge) posts untouched — they announce *events this session produced*, which are never duplicates; the dedupe applies to red failure alerts only.
3. Run `/workaholify`'s routine survey and refresh the live drive routines (verbatim, one at a time) so the fleet actually carries the rule.

## Considerations

- Reading the channel costs one Slack call per failing tick; a healthy tick pays nothing (the rule only runs on the failure path).
- Thread-reply-instead-of-suppress is a nicer UX but doubles the rule's surface; the ticket requires only suppression, and a reply/reaction is left as an allowed option, not a requirement.
- The signature must not include volatile detail (SHAs, timestamps) or every repeat would look "changed"; the precondition name + reason class is the right grain.
