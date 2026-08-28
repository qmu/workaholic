---
created_at: 2026-08-28T01:20:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-what-the-direction-could-not-see-before-calling-it-arrived
merge_policy:
verification_handoff: 
---

# Refuse an arrival over a tree we could not see

## Overview

`quiescent` is `false` when the residue read was **degraded**. Claiming a direction has
*arrived* on a blind read sends the operator to close it; the other readings only ask them
to look. That asymmetry is the whole justification, and it is why `dormant` is deliberately
left alone in this ticket — stating the asymmetry is part of the work, not a footnote.

This is the `unreadable`-is-never-`dormant` precedent and `no_feedback_refs`'s rule that a
gate that cannot be read is not a gate, applied to the one reading that speaks in the
vocabulary of completeness.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the `quiescent` block gains one term
- `plugins/workaholic/skills/strategy/scripts/direction-state.sh` — projects `arrived` from `quiescent`; read its precedence header, do not change it
- `plugins/workaholic/skills/propose/SKILL.md` — the `quiescent` contract
- `scripts/test-workflow-scripts.mjs` — inverts the characterization assertion from ticket 1
## Implementation Steps

1. Add the degraded-residue term to `quiescent` and to nothing else. A **non-empty** residue
   does not make `quiescent` false — an unattributed mission is not this direction's work,
   and treating it as one would be the inference this mission refuses. Only a residue we
   could not **read** refuses the arrival.
2. Leave `dormant` untouched, and write the asymmetry into the block's own comment: arrival
   invites a close, the other readings invite a look.
3. Invert ticket 1's characterization assertion: the fixture with a degraded residue read
   now answers `quiescent: false`, and the test's comment stops naming a pending inversion.
4. Confirm `direction-state.sh` needs no change — it projects `arrived` from `quiescent`,
   so a refused arrival simply never reaches the projection — and pin that its precedence
   (`unreadable` > `arrived` > `overdue` > `dormant` > `live`) is unchanged.
5. Check no gate moved: `refusal`, `pace`, `overdue`, `dormant`, the sort and `selected`
   stay byte-identical, exactly as the previous ticket pinned them.
## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A degraded residue read yields `quiescent: false` and therefore no `arrived` projection.
- A non-empty but successfully read residue leaves `quiescent` exactly as it was.
- `dormant` is unchanged, and the asymmetry is stated in the code's own comment.

**Verification method** — the commands/tests/probes that prove them:

- The hermetic case from ticket 1, inverted, plus a case for the honest non-empty residue.
- A case asserting `direction-state.sh`'s precedence is unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No gate, no sort and no `selected` moved.

## Considerations

- The tempting over-reach is making a non-empty residue refuse the arrival. That would let
  any unrelated mission in the tree suppress every direction's arrival forever, which is a
  different defect with the same shape. Only the **unreadable** case refuses.
## Final Report

Development completed as planned.

`quiescent` gains exactly one term: a **degraded** residue read makes it `false`. A non-empty
but successfully read residue leaves it exactly as it was, and `dormant` is untouched. The
asymmetry is written into the block's own comment: claiming a direction has *arrived* on a
blind read sends the operator to **close** it, while every other reading only asks them to
**look** — so only the reading whose next act is destructive is refused when the tree could
not be read.

`direction-state.sh` needed no change to its projection: `arrived` is projected from
`quiescent`, so a refused arrival simply never reaches it. It gained only the pass-through of
the residue itself, and its precedence (`unreadable` > `arrived` > `overdue` > `dormant` >
`live`) is pinned unchanged.

### Discovered Insights

- **Insight**: the fixture has to degrade the residue read **without** degrading the
  strategy, or the assertion passes on `unreadable` and never exercises the new term at all.
  `all_strategies_unreadable` cannot do it — every active strategy being unreadable makes
  *this* strategy unreadable too — so the test copies the plugin tree and removes
  `mission-strategy.sh`, leaving `dir1` perfectly legible and only the residue blind.
  **Context**: the near-miss is silent: the wrong fixture goes green and pins nothing.
- **Insight**: a non-empty residue refusing the arrival is the tempting over-reach and would
  let any unrelated mission in the tree suppress every direction's arrival forever — a
  different defect with the same shape.
  **Context**: recorded in the code's own comment beside the term, because the next reader's
  instinct will be to widen it.
