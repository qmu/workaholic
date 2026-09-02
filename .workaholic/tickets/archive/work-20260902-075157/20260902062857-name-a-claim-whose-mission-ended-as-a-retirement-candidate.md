---
created_at: 2026-09-02T06:28:57+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: retire-a-claim-whose-work-is-finished-or-abandoned
merge_policy:
verification_handoff: 
---

# Name a claim whose mission ended as a retirement candidate

## Overview

PROPOSED. `list-retirable-claims.sh` names two classes today — `superseded_only` and,
per branch, `pull_request_merged` / `pull_request_closed_unmerged`. A claim whose mission
was closed `abandoned` while its pull request is still open matches none of them, so it is
retired by nobody. Add that third class, bounded exactly as the other two are.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate
  reader; the per-branch arm is where the class joins.
- `plugins/workaholic/skills/drive/scripts/claim-mission-state.sh` — the previous ticket's
  reader, composed here and never reimplemented.
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act, whose
  bounds (`not_a_work_branch` / `release_branch` / `not_on_base` / `pull_request_open`)
  decide what this class may hand it.
- `.github/workflows/claim-retirement.yml` — the runner that acts on the candidates.
- `plugins/workaholic/skills/drive/reference/claims.md`, `CLAUDE.md` — where the class and
  its bound are stated.

## Implementation Steps

1. **Reproduce and localize first.** Show that a branch whose unit's mission is archived
   and whose pull request is open yields no candidate today, and name which arm dropped it.
2. Add `candidate_reason: mission_not_active` to the per-branch arm, keyed on
   `claim-mission-state.sh`'s `not_active`, carrying the mission's `status` on the row.
3. Keep every existing precedence: a **live** claim row beats it, a branch already named by
   the first class is not read twice, and an unreadable mission yields **no** candidate and
   its reason on `unreadable[]` — never a candidate.
4. Decide and state whether `delete_branch_on_merge`'s `pull_request_open` bound still holds
   for this class. The mission is abandoned but the pull request may be open, so the act
   would refuse; either the bound is widened for this reason with the argument written down,
   or the class closes the pull request first through `retire-claim.sh`'s existing order.
   Write the decision into `claims.md`; do not widen a bound silently.
5. Carry the `branch_empty` evidence onto the row as the other classes do — evidence, never
   a gate.
6. State the class in `claims.md` and in `CLAUDE.md`'s retirement paragraph, in the same
   commit.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A branch whose unit's mission is archived is a candidate with
  `candidate_reason: mission_not_active` and the mission's `status` on the row.
- A live claim row on that unit beats it and yields no candidate.
- An unreadable mission yields no candidate and appears in `unreadable[]` with its reason.
- A `batch-<ts>` unit is never named by this class.
- The delete act's behaviour under an open pull request is what `claims.md` says it is.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic cases in `scripts/test-workflow-scripts.mjs` over throwaway repositories, one
  per criterion, with no network and no `gh`.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- The strongest existing candidate is a proof about content (`superseded`). This one is a
  person's decision, which is weaker; the safety argument therefore has to be written, not
  assumed, and step 4 is where it is written.
- An abandoned mission's branch may hold work found on no other ref. Closing the mission
  `abandoned` is the operator saying that work is not wanted — the same reasoning
  `pull_request_closed_unmerged` already rests on — and `branch_empty` records how often it
  actually happens.

## Final Report

Development completed as planned.

### Step 1 — reproduced and localized before adding the class

A branch whose unit's mission is archived and whose pull request is **open** yielded no candidate,
and the arm that dropped it is the **second class's live-row test**, not the pull-request state
test the ticket's overview assumed. `list-retirable-claims.sh`'s per-ref arm walks
`refs/remotes/origin/work-*` and `continue`s on `live | single | ambiguous` — and a claim branch
carries a `Claim` commit by construction, so the oracle always holds a row for it and its
resolution is `single`. Every claim branch was therefore dropped before its pull request was read
at all, which is why even a *closed-unmerged* claim — the measured case — reached no class.

So the fourth class is enumerated from the **oracle's rows** rather than from the refs, and the
bounds are re-derived rather than inherited.

### Step 4 — the decision the ticket required, written down

**The `pull_request_open` bound is not widened.** Deleting the head branch of an open pull request
leaves it unmergeable by anybody forever — the headless shape this repository measured on `#813`,
`#799`, `#688`, `#635` and `#625`, every one of which a person had to close by hand. So the act's
bound stays exactly as it is, and `list-retirable-claims.sh` declines to offer such a branch at
all rather than handing the act a refusal it would repeat hourly. Closing the pull request is the
operator's own act; once they take it, the branch reaches the class on its own terms. Recorded in
`claims.md` beside the class, not only here.

### Discovered Insights

- **Insight**: The act's blanket `live | single | ambiguous` refusal had to be **narrowed per
  class, not loosened**. For the two pull-request classes any claim row at all is a live claim
  beating a fact about old work, because those classes exist for branches the oracle holds no row
  for. This class is enumerated *from* the rows, so refusing every row made it unreachable by
  construction.
  **Context**: What it refuses instead is exactly what the reader refuses — `live`, `ambiguous`,
  and a `claim_active` verdict. The hermetic row that proves the last one is the one that cost a
  fixture iteration: pushing an ordinary commit to build the *emptiness* case made the tip fresh,
  and the act correctly refused `not_superseded:claim_active` before reaching the gate under test.
- **Insight**: The emptiness gate is what keeps this class safe, and it is also what keeps its
  reach modest. An abandoned mission's claim branch usually still holds the work that was driven
  on it, so the act will refuse `branch_holds_work` and CI's record will name it — which is the
  signal a person needs. The class deletes the empty leftovers; the mission's other half (the
  stuck-work filter) is what stops the hourly question about the rest.
  **Context**: Issue #788 measured what assuming otherwise costs — two branches with ~300 lines
  present on no other ref, offered for deletion.
