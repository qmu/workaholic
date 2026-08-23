---
created_at: 2026-08-23T09:26:55+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission:
merge_policy:
feedback: [20260823092638-the-alert-cool-down-swallows-a-whole-working-day-when-a-failure-starts-in-the-evening.md]
verification_handoff: 
---

# Expire the alert cool-down at the next working day

## Overview

A red failure alert is deduped by its failure signature: before posting, read the channel's
recent history and suppress the same signature inside a **24-hour cool-down**, replying
`↳ still failing - <signature>, first reported <time>, <N> ticks` into the existing alert
instead. The suppression covers the top-level post only, and the reply is deliberately not
rate-limited.

The rule is right about what it prevents. Its defect is **where the 24 hours are measured
from** — the first report. A failure that begins in the evening therefore posts nothing at
channel level for the whole of the next working day, and everything it does say is a reply
buried in a thread from the day before.

**Measured** (2026-08-22 → 23): a unit blocked on an operator ruling from 21:38 JST. Eleven
consecutive ticks reported `blocked`, 2.1 agent-hours were spent, and the escalation worked
exactly as specified — every one of those reports was a `↳ still failing` reply inside the
previous day's feedback thread. Channel level showed nothing for ten hours, and the developer
asked why the channel had stopped updating. The cool-down was working correctly.

This is the same shape as the `over_cap` defect fixed the same day, and the sentence written
into that branch's story applies unchanged: *a per-tick refusal reads as a delay, and a delay
repeated twenty times reads as nothing at all.*

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the red-alert dedup paragraph carrying the
  24-hour cool-down, the `↳ still failing` reply and the precondition-stop escalation. Read the
  whole paragraph before changing it: the reply's exemption from rate-limiting and the
  "unreadable history posts anyway" clause are both load-bearing and must survive.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — owns the working-day gate and
  the quiet-hours window (`WORKAHOLIC_WORK_DAYS`, `WORKAHOLIC_QUIET_TZ`,
  `WORKAHOLIC_QUIET_HOURS`); the day boundary this ticket needs already exists there and must
  not be re-derived.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the alert shapes.
- `CLAUDE.md` — states the tick's posting behaviour.

## Implementation Steps

1. **Reproduce before changing anything.** Take the measured case — a signature first reported
   in the evening, still failing every hour — and confirm from the SKILL's own words that no
   top-level post is due until the same clock time the next day.
2. **Localize.** Confirm the cool-down is stated in exactly one place, and that the working-day
   boundary already exists in `ask-question.sh` rather than needing a new definition.
3. Change the expiry to the **earlier** of: 24 hours after the first report, or the **start of
   the next working day** in the workspace timezone. The second term introduces no new constant
   — it composes the day boundary and timezone that the quiet-hours gate already owns.
4. Make the re-posted root say **how long** it has been failing, not merely that it is failing:
   the news at that point is the duration, and a root identical to yesterday's is the
   restatement this repository retires posts for.
5. Leave untouched, and say so: the `↳ still failing` reply and its exemption from
   rate-limiting; the rule that a changed signature or a first report always posts a root; the
   rule that an unreadable history posts the alert anyway, because silence must never be
   produced by a failure of the mechanism that decides to be silent.
6. Update `notify/reference/notifications.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A signature first reported in the evening and still failing produces one top-level root at the
  start of the next working day, naming how long it has been failing.
- A signature first reported during the working day behaves exactly as before.
- The `↳ still failing` reply, the first-report rule and the unreadable-history rule are
  unchanged.
- No new timezone or day-boundary definition is introduced; the existing one is composed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Read-back of the dedup paragraph against the four criteria.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- This raises the alert rate by at most one post per signature per working day. That is the
  intent: the failure being reported is one nobody has acted on, and the cost of a second
  mention is bounded while the cost of the silence was ten hours of a stalled loop.
- Resist keying the escalation on the tick count instead. A count threshold is an arbitrary
  constant, and the thing that actually went wrong is that the person's working day passed with
  nothing to see — which is a boundary the repository already knows how to compute.
