---
created_at: 2026-08-30T04:28:03+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: catch-a-reported-claim-up-before-its-conflict-hardens
merge_policy:
verification_handoff: 
---

# Report each catch-up in the vocabulary that exists

## Overview

PROPOSED. The run report is the surface. `caught_up`, `already_current`,
`catch_up_refused: <word>` — the **same three words** the undelivered path already
reports, never a second set, because the outcome of a catch-up on a `queue_drained`
claim and on a `report_undelivered` one are the same kind of fact.

**A run that names a candidate and reports no outcome for it is non-conformant on its
face** — the enforcement the retry row and the connector retry already carry, for the
same reason: no mechanical check tells a real attempt from a claimed one, and what
the rule buys is that a silent report is visibly wrong.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract and its
  token table; the three catch-up words are already defined there for the
  `undelivered[]` path
- `plugins/workaholic/skills/drive/reference/routing.md` — the reported shape

## Implementation Steps

1. Report per candidate: the unit, and one of `caught_up` / `already_current` /
   `catch_up_refused: <word>`, the word being `catch-up-claim.sh`'s own, **verbatim**
   — a normalised word sends a reader to a string no script printed.
2. State the non-conformance rule in §7 beside the existing ones: naming a candidate
   and reporting no outcome for it is wrong on its face.
3. **It moves no token and gates nothing.** `catch_up_refused: content_conflict`
   moves none on its own recorded reasoning — a unit waiting on a person's judgement
   is the gate working — and neither does any other catch-up refusal by itself: what
   withholds `ok` is a unit's **delivery** outcome, which a refused catch-up leaves
   unchanged. Say so explicitly rather than leaving it to be inferred.
4. Add **no field to any artifact**: the branch carries the merge commit and the
   report carries the reading.
5. Update `CLAUDE.md`'s `/implement` row in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every candidate names exactly one of the three words, the refusal verbatim
- No token moves and no gate, route, demotion, claim or survey reads the outcome
- No artifact gains a field
- A run with no candidates reports nothing new

**Verification method** — the commands/tests/probes that prove them:

- The drill rows added by this mission's last ticket
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The three words are the existing ones; `git diff` adds no fourth

## Considerations

- Keep it to one line per candidate. The steady state is zero candidates and the
  interesting case is one or two; a per-claim block would be the report noise this
  repository has twice retired status roots for.
