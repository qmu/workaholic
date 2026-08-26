---
created_at: 2026-08-26T08:20:29+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-when-the-loop-has-run-out-of-direction
merge_policy:
verification_handoff: 
---

# Add the dormant reading to the strategy survey

## Overview

A live, in-date direction that nothing is answering is invisible. `/propose` reports
`no_evolutionary_move` — the honest answer — into a run report that on the day it
matters is read by nobody, and the direction stays eligible on every tick while
producing nothing. Add `dormant` as a named reading on every surveyed row: `active`,
owned, in date, legible, with nothing landed in the window, nothing waiting
(`waiting_missions + waiting_count == 0`) and no open proposal.

Every term is already computed by this script or by `attributed-work.sh` beneath it —
no new counter, no new field on any artifact, and no second derivation of `pace`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the row already
  carries `landed`, `waiting_count`, `waiting_missions`, `unreadable`, `feedback_refs`
  and the `$held` open-proposal set; `dormant` is a conjunction of what is there.
- `plugins/workaholic/skills/propose/SKILL.md` — stated beside `pace` and `overdue`.
- `CLAUDE.md` — the `/propose` row.

## Implementation Steps

1. Land the `overdue` reading first (this mission's first ticket): the two readings sit
   in the same `jq` object and a second edit to the same expression is cheaper once.
2. Derive `dormant` from, and only from, terms the row already holds: not `unreadable`,
   `status == "active"`, `owns == "mine"`, `days_to_target >= 0`, non-empty
   `feedback_refs`, `(.landed | length) == 0`, `waiting_missions + waiting_count == 0`,
   and the slug absent from the open-proposal set.
3. Emit it on every row, eligible and refused, exactly as `overdue` is.
4. Do not let it touch `refusal`, the sort, or eligibility. A dormant direction is
   eligible — that is precisely what makes its silence a finding rather than a gate.
5. State it in `propose/SKILL.md` and `CLAUDE.md` in the same commit, naming why it is
   not `pace: late` (which requires the date to be near) and not `no_citing_artifacts`
   (which the propose skill explicitly holds is not a refusal).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `dormant` appears on every surveyed row and is `true` only when every listed term
  holds
- A strategy whose attribution could not be read is never `dormant`; it stays
  `unreadable` and is named as such
- `refusal`, `pace`, the sort order and `selected` are byte-identical to before

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/propose/scripts/survey-strategies.sh | jq '.eligible +
  .refused | map({slug, dormant, overdue, pace, waiting_count, waiting_missions})'`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No artifact gained a field and no relation was added
- The documentation this change makes wrong is updated in the same commit

## Considerations

- `landed` is bounded by the survey's 14-day window while `waiting_*` is computed over
  the queue. That asymmetry is deliberate upstream and is inherited here rather than
  reconciled; the reading should say which term it read over which period.
- A brand-new strategy nothing has answered yet will read `dormant` immediately. That is
  correct — it is exactly the "no direction is being answered" state a person should be
  told about — but the question's wording (the fifth ticket) must not accuse anybody of
  neglect on the day a direction is filed.
