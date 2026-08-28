---
created_at: 2026-08-27T23:22:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-give-a-refused-delete-its-own-reported-word.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Ask the holder for the branches left undeleted

## Overview

A retirement the loop cannot finish reaches nobody. `step-retire-claims.sh` asks
nothing and its `needs_agent` is empty by design — correct while every retirement
either succeeded or was refused on a judgement, and wrong the moment a **proof** the
loop acted on leaves one act undone. The unit is then exactly the shape
`undelivered-units` and `handoff-units` exist for: a reading the machine cannot act
on, addressed to one person.

One question per blocked unit, keyed once, naming the branches and the recorded
refusal, addressed to the **claim holder**.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a finding reaches a person

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — where the
  blocked rows become candidates; the step keeps acting **and** starts asking.
- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the shape
  to follow: candidate set from the claim oracle, one key per unit, holder addressed.
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the sibling
  precedent, including its rule that one unit never draws two questions.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the asked-once gate,
  the per-tick cap, quiet hours and the working-day hold, all applying unchanged.

## Implementation Steps

1. Make each unit whose retirement was blocked on the delete a check-in candidate,
   keyed per unit (the `undelivered-unit:<unit>` / `handoff-unit:<unit>` shape) so
   the asked-once gate holds it to exactly one ask.
2. Address it to the **claim holder** — a real person who drove the unit and can
   delete its branch — following `stalled-units` on whose question it is. Resolve the
   address through `gather/scripts/identity.sh`; an unmapped login leaves the
   question addressed to nobody rather than stamping an address nobody verified.
3. Name in the question: the unit, the **exact branch** left on origin, the recorded
   refusal from ticket 2, and the acts that already stand. A question that does not
   name the branch does not tell the person what to delete.
4. Ask and nothing else. Never release the claim, never reopen the pull request,
   never re-run the delete on the strength of the answer, and never touch the
   `superseded` verdict — the proof gate is unchanged and the retirement's other two
   acts keep happening exactly as they do now.
5. Ensure no unit draws two questions across steps: check the sibling steps'
   candidate sets and filter, as `stalled-units` filters `awaiting_verification`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A blocked unit produces exactly one question, addressed to the claim holder,
  naming the branch and the recorded refusal.
- A second tick over the same blocked unit asks nothing.
- No claim is released, no pull request reopened, no verdict changed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`
- `sh scripts/e2e/loop-drill.sh verify-moderate`

**Gate** — what must pass before approval:

- The asked-once gate is proved over two consecutive ticks in the drill, not asserted.

## Considerations

- The step's `needs_agent`-is-empty rule is narrowed here, not reversed: it stays
  empty for a retirement that **succeeded**, because there is still no judgement for
  a person to make. What gains a question is the case where the act did not happen.
- A single unified "what the loop is blocked on" report across the four vocabularies
  was already refused for `handoff-units`, and is refused here for the same reason:
  four verdicts call for four acts by four people, and a report addressed to nobody
  is what two keyed roots were retired for.

## Final Report

Development completed as planned.

`step-retire-claims.sh` hands every unit whose retirement was **blocked on the delete** to the
check-in as one question, keyed **`retire-blocked:<unit>`** so `ask-question.sh`'s asked-once
ledger holds it to exactly one ask. The question names the unit, the **exact branch** left on
origin, the recorded refusal, and the acts that already stand.

**Whose question it is**: the **claim holder**'s, following `stalled-units` and
`undelivered-units` — a real person who drove the unit and can delete its branch. The address is
the claim row's own `author`; the **running identity is never consulted**, following
`undrivable-units`, because a branch left on origin is a fact about the repository and an hourly
question that depended on which container asked it would answer differently per account.

**Narrowed to the delete, deliberately.** A refused *reap* is local to this runner and tells its
holder nothing they can do remotely; a refused *close* is a different act with a different repair.

**No unit draws two questions** (step 5): every candidate here reads `superseded`, which
`step-stalled-units.sh` already filters out of its own candidates and counts as a finding instead
— so the pair was already honest and nothing new had to be filtered. The other two claim-reading
steps key on `report_undelivered` and `awaiting_verification`, which no `superseded` row can also
be.

**It asks and nothing else** (step 4): no claim released, no pull request reopened, no delete
re-run on the strength of an answer, no `superseded` verdict touched. The retirement's other two
acts happen exactly as they did.

The step's *`needs_agent` is empty* rule is **narrowed, not reversed** — a retirement that
succeeded still asks nothing at all, because there is still no judgement for a person to make.
That is what the drill's breaker row guards.

### Discovered Insights

- **Insight**: the empty-`needs_agent` rule was not wrong when written — it was **true of a world
  in which every retirement either succeeded or was refused on a judgement**. It became wrong the
  moment a *proof* the loop acted on could leave one act undone, which is a state the writer
  created and the caller never re-read.
  **Context**: a "this step asks nobody anything" contract is safe only while every outcome of its
  act is either complete or somebody else's business. Adding a new partial-failure outcome to a
  writer silently invalidates its caller's silence rule, and nothing mechanical catches that.
- **Insight**: the sibling filter needed **no** new code, because `stalled-units` already drops
  `superseded` for its own reason (a merged claim is a fact, not a question) — a rule written for
  a different purpose that happens to make the pair exclusive.
  **Context**: it is exclusive by coincidence rather than by construction, so the drill asserts it
  rather than the code enforcing it. If `stalled-units` ever stops filtering `superseded`, the two
  steps start asking about the same unit in different vocabularies.
