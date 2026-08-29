---
created_at: 2026-08-29T21:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
verification_handoff: 
---

# Ask a person when the evidence suggests a transition

## Overview

PROPOSED. The ask's *noticing* half: "stage transitions are the moments worth telling a
person about — *this direction can now cut over* (1→2) and *this direction has settled
into observation* (2→3) — rather than only overdue/dormant alarms."

`/moderate`'s `direction-health` step is where a reading reaches the person who owns a
direction, and its discipline is exact: it **asks and nothing else**, one question per
key, addressed to the direction's assignee, keyed so it is asked exactly once, silent for
a direction that already has a non-`live` question this tick, and it never writes to the
strategy. Two new keys join it: **`direction-cutover:<slug>`** (1→2) and
**`direction-settled:<slug>`** (2→3).

**The question is a candidate, never a verdict** — `arrived`'s own standing rule. The
evidence can only suggest; the operator's announcement is what moves the field, through
`amend.sh`. The tick moves nothing.

**And the stage is never inferred from stuckness.** The ask states it outright: a
handoff, a block or an undecided unit occurs in any stage. So neither question may be
derived from a claim verdict, a blocked run or a queue that will not drain — the
candidate set is built only from the readings that describe *work landing*.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/change-control.md` — a machine asks; a person declares

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the two new
  keys, their candidate sets, their addressee and the one-question-per-direction rule.
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — the row this composes
  from; it gains nothing here beyond the `stage` an earlier ticket carried onto it.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract and the
  finding classification table `file-findings` reads.
- `plugins/workaholic/skills/notify/reference/notifications.md` — question shapes, if a
  new one is needed.
- `CLAUDE.md`.

## Implementation Steps

1. Read `step-direction-health.sh` whole, plus `strategy/SKILL.md`'s *`arrived` is a
   candidate, never a verdict* — the candidate discipline and the one-question rule are
   the contract this extends.
2. Derive the **1→2** candidate from readings already on the row: a 進行中 direction whose
   attributed work has landed with nothing waiting (`quiescent`) is the honest signal that
   cut-over may now be possible. Name in the question **what landed**, and that the
   reading cannot know whether a toggle can be flipped — only the operator can.
3. Derive the **2→3** candidate the same way: a 改良中 direction that is `quiescent` **and**
   has had no proposal and nothing landing across the survey's own window. Introduce **no
   new threshold** — reuse the window `pace` is already derived against, as `expiring`
   did.
4. Refuse any derivation from a handoff, a block, a stale claim, an undelivered unit or a
   drained-but-open queue, and state that refusal in the step header with the ask's own
   words: stuckness is orthogonal to the stage.
5. Key each question `direction-cutover:<slug>` / `direction-settled:<slug>` through
   `ask-question.sh`, so the asked-once gate, the per-tick cap, quiet hours and the
   working-day hold all apply unchanged and no second ledger exists.
6. Keep the existing one-question-per-direction rule: a direction that already drew
   `arrived`, `overdue`, `expiring`, `dormant` or `last` this tick draws no transition
   question, because one direction asked twice in two vocabularies is the doubling
   `handoff-units` and `stalled-units` were split to avoid.
7. Address it to the direction's assignee, resolved as the step already resolves it; an
   unresolved address leaves the question addressed to nobody rather than stamping one.
8. A degraded reading asks nothing and is named — a reading we could not make is not a
   transition.
9. Classify both keys in `moderate/reference/workflow.md`'s findings table as
   `needs_ruling`: which stage a direction is in is precisely what a machine may not
   decide, so neither may be filed as repairable work.
10. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A 進行中 direction whose work has all landed draws one `direction-cutover:<slug>`
  question, once, addressed to its assignee.
- A settled 改良中 direction draws one `direction-settled:<slug>` question, once.
- No question is derived from a handoff, a block, a stale claim or an undelivered unit.
- The step still writes nothing anywhere but its own tick-log line, and moves no stage.
- A direction with another non-`live` question this tick draws no transition question.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`

**Gate** — what must pass before approval:

- The suite still fails if `direction-health`'s closure reaches `create.sh`, `amend.sh`
  or `close.sh`, or writes under `.workaholic/strategies/`.

## Considerations

- The 1→2 signal is the weaker of the two: "can this be cut over" is a fact about a
  feature toggle no script can see, so the question must describe the evidence and ask,
  never assert. That is stated in the body rather than left to tone.
- The key carries the slug and the transition, not the stage, so each direction is asked
  about each transition **at most once ever**. The cost is stated rather than hidden: an
  operator who declines a cut-over question is not asked again when the evidence returns.
  That is the same bound every other `direction-*` key already accepts, and the loud
  alternative — re-asking whenever the reading recurs — is the hourly restatement this
  repository has retired posts for twice.
