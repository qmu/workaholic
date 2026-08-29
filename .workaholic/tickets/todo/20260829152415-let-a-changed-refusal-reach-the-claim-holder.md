---
created_at: 2026-08-29T15:24:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Let a changed refusal reach the claim holder

## Overview

PROPOSED. `retire-blocked:<unit>` is asked exactly once per unit, ever. That gate is
right for an unchanging block — an hourly restatement of the same refusal is the
noise two keyed roots were retired for — and wrong the moment the **word** changes:
a unit first blocked on `branch_delete_failed` and later blocked on
`pull_request_open` is a different fact needing a different act, and the second one
reaches nobody.

This ticket narrows the asked-once discipline **on the refusal word alone**: a
changed word re-asks, an unchanged one stays held. It is a narrowing, not an
abandonment, and the ticket must state why in the same terms the gate's own history
uses.

## Policies

- `workaholic:operation` / `policies/incident-response.md` — a blocked act must reach a person
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the asked-once gate, keyed on the
  step id derived from the question key
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the step that composes the
  key and the summary
- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — the one derivation of a
  question id, shared by the gate, the writer and the reader
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — how an earlier tick's ask is found

## Implementation Steps

1. **Carry the refusal word into the question key**, so a changed word is a new key and an
   unchanged word is the same key. The asked-once gate then needs **no change at all** — which is
   the property to aim for: the gate stays one mechanism, and the narrowing lives in what the key
   is made of.
2. **Keep the key readable and stable.** It is composed through `lib/question-id.sh` like every
   other, and the human-facing text still names the unit, the exact branch left on origin, the
   refusal and the acts that already stand. A question that does not name the branch does not say
   what to delete.
3. **State the narrowing where the gate's rules live** (`moderate/reference/workflow.md`): asked
   once **per (unit, refusal word)**, never per unit; an unchanged word is held forever, which is
   the discipline the change preserves rather than drops.
4. **Do not let the summary become an hourly restatement.** Every term of the step's `summary`
   stays a function of the claim set and the act states alone, so an unchanged block renders an
   identical summary and, with `event` empty on a tick that retired nothing, no root line. A
   **newly worded** block moves the summary the hour it appears — which is the same rule the step
   already holds for a newly blocked unit.
5. **Respect the holds unchanged**: quiet hours, working days, the per-tick cap and the day cap all
   apply first. A re-ask is one more question, subject to every existing bound.
6. **Keep the step asking and nothing else** — no claim released, no pull request reopened, no
   delete re-run on the strength of an answer.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose refusal word changes draws exactly one new question; a unit whose word is unchanged
  draws none, however many ticks run.
- The question names the unit, the branch, the refusal word and the acts already standing.
- An unchanged block renders an identical summary and no root line.
- Every existing hold and cap applies to the re-ask.

**Verification method** — the commands/tests/probes that prove them:

- A drill row over two ticks with one word, then a third tick with a different word: one question,
  then none, then one.
- `sh scripts/e2e/loop-drill.sh verify-retire` passes, including its held-block row.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No second ledger and no cursor: the derivation still reads the tick log the loop already keeps.

## Considerations

- **The alternative — re-asking on a timer — is refused** and the refusal belongs in the record: it
  reintroduces exactly the hourly restatement the asked-once gate exists to prevent, and a word
  that has not changed carries no new information for the person.
- Folding the word into the key rather than teaching the gate a second mode is deliberate: one
  mechanism cannot drift from itself.
- A word that oscillates between two values would re-ask on each flip. Whether that needs its own
  bound is worth measuring before adding one; do not add a threshold on speculation.
