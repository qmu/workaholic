---
created_at: 2026-08-29T06:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# Name the catch-up outcome in the run report

## Overview

PROPOSED. Per unit: `caught_up`, `catch_up_refused: <word>`, `already_current`, beside the
delivery outcome it produced. A run that names a candidate and reports no outcome for it is
**non-conformant on its face** — the connector retry's enforcement, for the same reason: no
mechanical check tells a real attempt from a claimed one, and what this buys is that a report
naming no outcome is visibly wrong.

**No artifact gains a `caught_up` field.** The branch carries the merge commit and the report
carries the reading; a field would be a third store of a fact two places already hold.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the run report contract, where the three words
  are stated.
- `plugins/workaholic/skills/drive/reference/routing.md` — the per-unit report rows.
- `CLAUDE.md` — the `/implement` contract row.

## Implementation Steps

1. State the three outcome words in the run report contract, beside the merge vocabulary
   rather than inside it — a catch-up and a merge are different acts.
2. State the non-conformance rule explicitly: a named candidate with no reported outcome.
3. Decide and state whether a `catch_up_refused: content_conflict` moves the terminal token.
   The precedent is `claimed_awaiting_verification` — a unit waiting on a person's judgement
   is the gate working — so it should **not** move the token, and the reasoning must be
   written down rather than left to be re-derived.
4. Update `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Three words, never collapsed into the merge vocabulary.
- The non-conformance rule is stated, with its reason.
- The token decision is stated with its reasoning, whichever way it goes.
- No artifact gains a field.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The documentation drift check is clean and no new frontmatter key appears anywhere.

## Considerations

The pull toward a fourth word for *caught up and then delivered* should be resisted: that is
two facts, already reported by two existing vocabularies.

## Final Report

Development completed as planned. The three words — `caught_up`, `already_current`,
`catch_up_refused: <word>` — are stated in `drive/SKILL.md` §7, in
`drive/reference/routing.md`'s per-unit report rows, and in `CLAUDE.md`'s `/implement` row, in
the same change. They sit **beside** the merge vocabulary rather than inside it, with the reason
written down: a catch-up moves the branch and a merge moves the pull request, and collapsing
them would leave a reader unable to tell a unit the loop could not reconcile from one the
transport would not merge.

The pull the ticket warned about is resisted explicitly and in writing: a **fourth** word for
*caught up and then delivered* is refused in all three places, because that is two facts and two
vocabularies already report them.

The non-conformance rule is stated with its reason — no mechanical check tells a real attempt
from a claimed one, so what the rule buys is that a report naming an entry and no catch-up
outcome is visibly wrong, exactly as the connector retry's is.

**The token decision is stated with its reasoning, and it is: no.**
`catch_up_refused: content_conflict` moves no token, on `claimed_awaiting_verification`'s own
precedent — a unit waiting on a person's *judgement* is the gate working, and making it
`pending` would put `ok` out of reach for as long as that person takes, on precisely the runs
where the machinery did its job. Every other catch-up refusal moves no token by itself either,
for the survey rows' reason: what withholds `ok` is the unit's *delivery* outcome, which a
refused catch-up leaves exactly where it was. The person is reached by `/moderate`'s
`catchup-blocked:<unit>` question, not by the token.

No artifact gained a field: `layout-doctor.sh` is conforming, and the only frontmatter keys the
branch adds are the claim protocol's own `claim:` and `status: done` stamps.

### Discovered Insights

- **Insight**: Writing the token decision down is what stops it being re-derived, and the
  precedent to cite is the one whose *shape* matches rather than whose subject does.
  **Context**: `claimed_awaiting_verification` is about a declared handoff and this is about a
  merge conflict, but both are "a person's judgement is the next step", which is the property
  the token rule keys on.
