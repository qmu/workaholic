---
created_at: 2026-08-18T21:46:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818202549-make-the-housekeep-notification-reflect-the-tick-s-actual-findings.md]
merge_policy:
verification_handoff: 
---

# Measure and bound the Prepare Release post rate

## Overview

<!-- MINTED MID-RUN by the /implement run that drove
     `20260818202706-make-the-housekeep-check-in-carry-its-findings.md`. That ticket's
     Open Decision 1 named two readings of issue #513 and forbade doing both under it:
     (a) the `🔧` heading, which that run implemented, and (b) the channel's noise in
     aggregate, which is this ticket. Filed rather than fixed, because (b) changes a
     routine that ticket does not name. -->

Reading `#dev-workaholic` for issue #513 measured the whole channel, not only
housekeep's share of it, and the aggregate finding is that **`[Prepare Release]` is the
channel's dominant poster.** Over roughly fourteen hours on 2026-08-18 it posted at least
nine `📦` lines while `[Housekeep]` posted two `🔧` and two `❓`. Every `📦` line asked for
the same act — cut a release — and the counts read 16 → 18 → 22 → 25 → 30 → 36 → 165 →
181 → 3.

**Two causes, and they are not the same problem.** The swinging counts are the stale-refs
defect closed the same day (issue #503, `report-deploy-status.sh` now freshens the base
and tags and reports `refs`/`doubtful`), so that half may already be fixed and the
measurement above predates the fix landing everywhere. What is **not** addressed is the
rate: the post's gate is `deploy:<digest>` over the boundary state, and that digest
changes whenever a commit lands on the base — so on an active day the tick posts every
hour, each time with the same actionable content. The dedup prevents a *repeat*; it does
not prevent an *hourly restatement of the same request*.

## Policies

- `workaholic:design` / `policies/user-experience.md` — cognitive load of what a human reads
- `workaholic:operation` / `policies/runtime-behavior.md` — the tick's reporting contract
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` — the read the tick
  reports from, and where `doubtful` was added.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `📦 Release
  Preparation` shape and its two posting gates.
- `plugins/workaholic/skills/workaholify/routines/prepare-release.md` — the routine
  prompt, byte-identical copy of the shape; a shape change is a change here too.
- `plugins/workaholic/skills/prepare-release/SKILL.md` — the command's contract, including
  what it must never write.

## Implementation Steps

1. **Measure first, over a week, after the #503 fix.** Count `📦` posts per day and how
   many distinct *requests* they represent. The nine-in-fourteen-hours figure above is
   from the window that contained the stale-refs defect; if the fix alone brought the rate
   down, the rest of this ticket may be unnecessary and saying so is the outcome.
2. Decide what the right bound is, and record why. Candidates, none recommended here: a
   post-once-per-day floor like the note cadence's `Asia/Tokyo` day; a threshold on the
   *change* in the count rather than any change to the digest; or leaving it hourly
   because the request is genuinely still open. The comparison is `[Standup]`'s stricter
   rule — a daily post is a standing claim on attention, so it stays silent unless
   something moved.
3. Whatever is chosen must not weaken the existing gates: an idle tick still posts
   nothing, and a `doubtful` read is still reported rather than hidden.
4. Keep `deploy:<digest>` as the dedup key and do not touch the heading. It has moved
   twice in two days already (issue #485, then #504) and nothing searches it.
5. Update `CLAUDE.md`, the notify reference and the routine template in the same change if
   any shape or gate moves.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A week of measured post counts is recorded, taken after the #503 fix landed.
- The rate decision is recorded with its reasoning, including the case for changing
  nothing.
- If a bound ships: an idle tick still posts nothing, a `doubtful` read is still reported,
  and `deploy:<digest>` is unchanged in derivation and format.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-status` and `verify-cadence`
- Read `#dev-workaholic` over the measured window and count the posts.

**Gate** — what must pass before approval:

- The measurement exists, the ruling is written down, and the tests and both drills pass.

## Considerations

- **This may correctly end in no code change.** The honest outcome of step 1 is possibly
  "the #503 fix was the whole problem". A ticket that measures and then declines is a
  finished ticket, not a failed one.
- The complaint that provoked this is about **attention**, and the fix for attention is
  usually fewer posts rather than better ones — the opposite of what the sibling ticket
  did to the `🔧` heading, and deliberately so: that post is rare and was uninformative,
  this one is frequent and is already clear.
- Nothing here ingests a Slack reply back into the loop, and this ticket does not change
  that (the sibling ticket's Open Decision 2, ruled the same way).
