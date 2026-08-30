---
created_at: 2026-08-30T02:21:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Carry the age on retire-blocked and undelivered-unit

## Overview

PROPOSED. The two questions about acts the loop takes on a **proof** — a retirement whose branch
delete neither the container nor CI could take, and a unit the loop finished and could not
deliver. Each is keyed on the unit it already names, and each is exactly the shape where *how
long* is the fact that makes a person act: three proved-superseded branches have stood since
2026-08-21, and undelivered pull requests have sat green and unmerged for days.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the `retire-blocked:<unit>:<word>`
  question; note its key **already carries the refusal word**, which is what makes a changed word
  draw exactly one more question.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the
  `undelivered-unit:<unit>` question.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — composed per candidate.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — both steps' contracts.

## Implementation Steps

1. In each step, call `condition-age.sh --key "$key"` per candidate with the key that step
   already composes, and attach the reading verbatim as `age`.
2. Extend each step's `compose` prose to name the age when there is one, alongside what it
   already names — the unit, the exact branch, the refusal and the acts that stand for
   `retire-blocked`; the pull request, its age and the refusal for `undelivered-unit`.
3. **`undelivered-unit` already names a pull-request age** from the pull request's own coordinates.
   Keep that number and add the tick-log one as a **second, distinct** fact — how long it has been
   *asked about* versus how long the pull request has been *open* — or omit the second when it
   adds nothing. Do not let one number silently replace the other; ticket 5 records which
   question reads which source, and this is the one step where both are present.
4. **Neither step summary moves.** `step-retire-claims.sh`'s header states that every term of its
   summary is a function of the claim set and the act states alone, so an unchanged block renders
   an identical summary and no root line; `step-undelivered-units.sh`'s states the same rule.
   Adding an age to either summary would restore the hourly restatement both were written against.
5. **No key moves**, so `already_asked`, the caps, the holds and `retire-blocked`'s
   changed-word narrowing are all byte-identical.
6. Neither step gains an act: `retire-claims` still calls `retire-claim.sh` and asks only about a
   blocked delete; `undelivered-units` still asks and merges, closes and claims nothing.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both steps attach an `age` per candidate, carrying the reader's words verbatim.
- Both steps' `summary` strings are byte-identical to their pre-change forms for the same inputs.
- All candidate keys are byte-identical, including `retire-blocked`'s refusal-word suffix.
- On `undelivered-unit`, the pull-request age and the tick-log age are distinguishable in the
  composed question and neither is presented as the other.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — summary-identity and key-identity rows for both steps.
- `sh scripts/e2e/loop-drill.sh verify-retire` and `verify-delivery-retry` still pass unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; both drills pass; both summaries and all keys
  unchanged.

## Considerations

- `retire-blocked`'s key carries the refusal word, so a unit whose refusal **changes** starts a
  new key and its age resets to `first_seen: null`. That is correct — it is a different question
  — and it must be stated in the step, so a reader does not read the reset as the block having
  cleared.
- Both steps read `list-claims.sh` and never `plan-units.sh`; that does not move.

## Final Report

Development completed as planned. Both steps attach the reader's words verbatim as `age` on
each candidate, both summaries and every key are byte-identical, and `undelivered-unit` names
the pull request's `open_hours` and the tick-log `age` as two distinct facts.

### Discovered Insights

- **Insight**: On `retire-blocked` the age must be attached AFTER the key is composed and after
  both suppressions.
  **Context**: The key is `retire-blocked:<unit>:<blocking_refusal>`, and the refusal word is
  resolved from the CI turn several blocks below the candidate build. An age read under any
  earlier key would answer about a different question. It also has to come after the act:
  `retire-claims` is the one age consumer that acts, on a proof, and a judgement must never sit
  in front of the proof `retire-claim.sh` reads — the suite pins that ordering by position.
- **Insight**: A changed refusal word resets the age, and the composer has to be told so.
  **Context**: The key carries the word, so a unit whose block changes cause starts a new
  question and reads `first_seen: null` on its first tick. Without the instruction a composer
  would render that reset as the block having just started, when the branch has been standing
  all along and only what blocks its delete has moved.
