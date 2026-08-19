---
created_at: 2026-08-18T21:46:15+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818202549-make-the-housekeep-notification-reflect-the-tick-s-actual-findings.md]
merge_policy:
verification_handoff: 
claim: work-20260818-222423
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

## Final Report

Development completed as planned, with one stated deviation on the measurement window.

**The measurement.** `#dev-workaholic` was read end to end (153 message blocks, back to
2026-08-09). Every `📦` post, newest first, with its JST timestamp and count:

| Window | Posts | Counts |
| ------ | ----- | ------ |
| After the #503 fix (23:11 JST 2026-08-18 → 07:47 JST 2026-08-19) | **9 in 9 consecutive hours** | 10, 12, 14, 16, 18, 22, 30, 2, 2 |
| Before it (18:47 JST 2026-08-17 → 21:47 JST 2026-08-18) | 13, with gaps | 98, 91, 85, 81, 61, 201, 36, 25, 16, 9, 181, 165, 3 |

**Distinct requests behind the nine post-fix posts: one** — "cut a release for
marketplace". Not one hour was silent, and the two `2`s are the same request restating
itself immediately after a release was cut at ~06:00 JST.

**The deviation, stated rather than glossed:** the ticket asks for *a week* of counts
after the fix. The fix landed 9 hours before this run (commit `c5dfedcd`,
2026-08-18T14:11:52Z), so a week does not exist to measure and waiting for one would
park the ticket for six days. Nine consecutive hours at 9/9 is not a sample that a
longer window overturns: the mechanism is deterministic (`unreleased_count` is in the
digest's input; a commit lands on the base every hour on an active day), and the
pre-fix window confirms the same rate under a different defect. Recorded here so a
reader knows the claim rests on 9 hours, not on 7 days.

**The ruling.** Step 1's escape hatch — "if the #503 fix alone brought the rate down,
the rest of this ticket may be unnecessary" — is measurably closed. The fix cured the
**accuracy** half (the 2721/181/165 swings are gone; the post-fix counts are monotone
and true) and left the **rate** untouched. The bound shipped is a **second, day-scoped
token**: `` `deploy-day:<day_token>` ``, where `day_token` is
`<Asia/Tokyo day>:<hash of the per-target `needs` sets>` — what the tick is *asking
for*, not how much of it there is. Both token searches are required, still AND'd with
`actionable || doubtful`.

Rejected, with reasons recorded in `workaholic:ship` §7 and the script header:

- **Narrowing the digest** (dropping `unreleased_count` from its input) — the obvious
  fix, and refused. The derivation had been settled hours earlier the same day (the
  doubtful redaction), and re-cutting a dedup key a day later is the churn this ticket
  is about. It is also what the acceptance criterion forbids.
- **A threshold on the change in the count** — the ask is no more urgent at 20 than at
  10, so any constant would be arbitrary.
- **Leaving it hourly** — the case for changing nothing, recorded rather than
  dismissed: the request genuinely is open every one of those hours. It loses to the
  measurement; nine identical asks in nine hours is how a channel teaches its readers
  to stop reading it. Its one real cost — a renewed ask unsaid for the rest of the day
  — is bounded by keying on `needs` rather than on the clock alone, so a **new kind** of
  ask still posts the same hour.

**Every constraint the ticket set is met.** An idle tick still posts nothing
(`actionable` gate untouched); a `doubtful` read is still reported (untouched, and the
day token redacts a doubtful target's needs exactly as the digest redacts its count);
`deploy:<digest>` is unchanged in derivation and format (asserted by a test that would
fail if a later change folded the bound back into it); the heading did not move; the
`📦`, the mention-token rule and both existing gates are untouched. The token rides the
**same line** as the digest, so the post that provoked a complaint about attention did
not get taller.

### Discovered Insights

- **Insight**: A content-hash dedup is not a rate bound whenever any *quantity* is in
  its input. `deploy:<digest>` hashed `unreleased_count`, which moves whenever a commit
  lands, so the key changed hourly for a request that did not — the dedup worked exactly
  as specified and still produced nine posts for one ask.
  **Context**: The distinction that fixes it is *what is being asked for* versus *how
  much of it there is*. `needs[]` was already computed and already the right granularity;
  the bound needed no new state, only a second hash over the half that does not churn.
  Any future recurring post in this system should be checked against the same question
  before it is called deduplicated.

- **Insight**: `TZ=<zone> date` does not fail on a container with no tzdata — it silently
  answers UTC. A zone must be **read back** (`date +%z`), not asserted.
  **Context**: `report-deploy-status.sh` reports `tz` as the zone that actually answered,
  so a fallback container says `UTC` instead of claiming `Asia/Tokyo`. Without the
  read-back the day boundary would be wrong by nine hours while every field said
  otherwise — the same class of invisible degradation the refs fix (#503) had just
  removed from the count.

- **Insight**: The two shapes in `notify/reference/notifications.md` and the routine
  template are pinned byte-for-byte by `test-workflow-scripts.mjs`, so a shape edit is
  mechanically a two-file edit.
  **Context**: The pin was added on 2026-08-18 after two heading renames in one day
  landed in one copy. Any change to a post's tokens or lines must touch both files in the
  same commit or the suite fails — which is what caught the degraded variant here.
