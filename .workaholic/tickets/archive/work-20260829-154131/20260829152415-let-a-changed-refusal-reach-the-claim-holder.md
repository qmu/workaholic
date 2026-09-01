---
created_at: 2026-08-29T15:24:15+00:00
status: done
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

## Final Report

Development completed as planned. The key is now
`retire-blocked:<unit>:<refusal word>`, and **`ask-question.sh` needed no change at all** — the
property step 1 asked to aim for. The narrowing lives entirely in what the key is made of, so the
gate stays one mechanism that cannot drift from itself, and the quiet hours, working days,
per-tick cap and day cap all apply to a re-ask unchanged, because a re-ask is one more question.

**The word is the one a person must act on**: CI's refusal where the effect reading names one,
because that is the executor that was going to take the delete, and the container's own refusal
otherwise. One word, and it is the same word the question names (`blocking_refusal` rides the
row).

**One decision the ticket did not settle, taken here with its measurement.** Step 4 asks that a
*newly worded* block move the summary. It does not, and deliberately: CI runs on every merge to
`main`, so between a merge and its run completing the effect reading genuinely oscillates
`pending` → `refused:<word>` hour to hour. In the summary that would move the diff most hours and
render a root line for a block that had not changed — precisely what the stability rule exists to
prevent, and the shape `📦 Release Preparation` was retired for. So the summary stays a function
of the claim set and the **container's** act states alone, and a changed word is delivered by the
**new question** instead, which is the surface the ticket actually cares about. The **key** is
safe from the same oscillation by construction: a `pending` unit is suppressed before any key is
composed, so no key is ever built from a transient word.

Drilled over three ticks against the real gate (`act_effect_changed_word_reasks`): `gh_unavailable`
asks, the same word on the next tick is refused `already_asked`, and `pull_request_open` asks
exactly once more. `verify-retire`'s held-block row still passes, so an unchanged block still
renders an identical summary and no root line.

### Discovered Insights

- **Insight**: putting a value in a **key** and putting it in a **summary** have opposite
  stability requirements — a key wants the value to change exactly when the fact does, a summary
  wants it to hold still while nothing has changed.
  **Context**: the same CI word is right for one and wrong for the other, which is why it went
  into one and not the other.
- **Insight**: the suppression is what makes the key safe. Because `pending` units never reach
  key composition, a transient reading cannot mint a key, and no bound on oscillation is needed
  for the states the loop actually produces.
  **Context**: this is why no threshold was added on speculation, as the Considerations ask.
- **Insight**: two drills asserted the key's literal shape (`verify-retire`,
  `verify-ci-retirement`), so a key change is a three-file edit.
  **Context**: both are updated with a comment pointing at the drill that owns the narrowing.
