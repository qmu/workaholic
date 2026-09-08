---
created_at: 2026-09-08T19:00:00+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: turn-quiescent-blockers-into-mature-decisions-and-resume-work
feedback: 20260908123159-make-quiescent-loops-surface-decision-ready-blockers-and-reopen-after-answers.md
merge_policy:
verification_handoff:
---

# Reconcile the survey's observing refusal with its ladder

## Overview

`propose/scripts/survey-strategies.sh` documents an `observing` refusal — *the operator DECLARED
this direction 観察中 — settled, the loop reactive only*, with three paragraphs on where it sits
in the ladder and why — and its refusal expression does not emit that word. `commands/propose.md`
states the current rule instead (`観察中` permits observation work and guides the hypothesis), so
the header describes a gate that was retired and the sort comment still asserts it
(*観察中 never reaches this sort at all — it is refused `observing` one step above*).

Observed while driving `20260908123303-judge-whether-a-human-decision-is-mature-enough-to-block`:
the first draft of the maturity ladder keyed a rung on `reason == "observing"` and was dead code.
The reader now tests the declared stage off the row instead, which is correct either way — this
ticket is about the documentation that misled it, not about that reader.

Decide which is true and make one statement of it: either the ladder should refuse `observing`
and the code is missing a rung, or the refusal is retired and three blocks of prose describe a
gate that does not exist. This ticket does **not** presume the answer; it requires that the tree
stop saying both.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the header's gate table
  (the `observing` entry), the refusal ladder, and the sort comment that names the refusal.
- `plugins/workaholic/commands/propose.md` — states the current rule (`観察中` permits
  observation work).
- `plugins/workaholic/skills/propose/SKILL.md` — the stage's role in the hypothesis.
- `plugins/workaholic/skills/moderate/scripts/decision-maturity.sh` — a reader that tests the
  declared stage rather than the refusal word, and says why in its own header.

## Implementation Steps

1. Establish which rule is current — whether a `観察中` direction may be proposed against — from
   `commands/propose.md`, `SKILL.md` and the git history of the ladder.
2. Make the tree state it once: either restore the rung, or delete the retired gate's prose from
   the header table and correct the sort comment.
3. Leave `decision-maturity.sh` reading the declared stage either way, and say in its header why
   it does not depend on another script's refusal word.
4. Pin the outcome in `scripts/test-workflow-scripts.mjs` so the ladder and its documentation
   cannot drift apart again.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The refusal ladder and every sentence describing it agree on whether `observing` is emitted.
- No consumer keys on a refusal word the ladder does not produce.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, with a row asserting the ladder's emitted refusal
  words match the set its own header documents.

**Gate** — what must pass before approval:

- The origination behaviour of a `観察中` direction is unchanged unless the investigation
  concludes the code was the defect, and the change says which conclusion it took.

## Considerations

The two readings have different blast radii: restoring the rung silences origination for every
`観察中` direction, while deleting the prose changes no behaviour at all. Prefer the one the
evidence supports, and state the other explicitly as the fork not taken.
