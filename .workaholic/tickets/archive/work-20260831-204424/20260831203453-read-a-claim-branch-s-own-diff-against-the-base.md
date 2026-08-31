---
created_at: 2026-08-31T20:34:53+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: prove-a-claim-branch-is-empty-before-deleting-it
merge_policy:
verification_handoff: 
---

# Read a claim branch's own diff against the base

## Overview

PROPOSED. The fact `superseded` is asserting — this branch holds nothing that is not on the
base — is one git call away and has never been made. This ticket adds the reading alone: a
three-valued answer about one branch, composed by the next ticket into the proof. Separating
it keeps the derivation change small enough to reason about, and gives the question a home
that consumers can read without acting.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where the reading belongs, beside
  the other tree-derived helpers the proof already composes.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the precedent for a
  branch-level tree reading that touches no worktree, index, ref or extra network call.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the reading's vocabulary and
  its consumers are recorded.

## Implementation Steps

1. Add one reading over a branch ref and the base: is this branch's diff against their merge
   base empty? `git merge-base` plus `git diff --quiet` — no worktree, no index, no checkout,
   no extra network call, following `claim-mergeability.sh`'s shape.
2. Make it **three-valued and name the third**: empty, non-empty (with the files, bounded), or
   **unanswerable** with its own reason — an absent ref, a shallow graft boundary, a git
   failure. An unreadable diff is never "empty": that is the direction that loses work.
3. Decide and state which paths, if any, are subtracted. The protocol's own bookkeeping — the
   claim commit, a heartbeat, a resume commit — may leave an empty tree diff already; if it
   does not, say so in the header rather than subtracting paths on a hunch. Anything subtracted
   here is content the loop is willing to delete unseen, so the list must be short, explicit
   and justified.
4. Exit 0 in every case, including every degradation, as every reader in this chain does.
5. Record it in `drive/reference/claims.md` as a **reading**, naming its consumers. It is not a
   verdict word and adds no row to the verdict table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A branch whose content is entirely on the base answers empty.
- A branch holding a file absent from the base answers non-empty and names it.
- A shallow or absent ref answers unanswerable with its reason, never empty.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` over throwaway repositories, one per
  case above, including a shallow clone.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The reading performs no network call beyond what the caller has already fetched, and touches
  no ref, index or worktree.
- Nothing acts on it in this ticket.

## Considerations

- A squash-merged branch is never an ancestor of the base, which is exactly why the existing
  proof is derived from the tree rather than from ancestry. The diff term must be derived the
  same way, or it will answer non-empty for every squash-merged branch and refuse every
  legitimate retirement.
- Bound the file list. A branch with a thousand differing files should report a count and the
  first few names, not a thousand names into a question.

## Final Report

Development completed as planned. The reading is added and nothing acts on it yet.

`claims_branch_diff_reading <base> <branch-ref> <stamped-artifacts-csv>` in
`plugins/workaholic/skills/drive/scripts/lib/claims.sh` answers one JSON line —
`{"state", "reason", "files", "count"}` — with three states: `empty`, `non_empty` (the first
`CLAIMS_BRANCH_DIFF_MAX`, default 5, paths named beside the full count) and `unanswerable`
with its own reason (`no_ref` / `no_merge_base` / `shallow_history` / `diff_failed`). It exits
0 in every case, makes no network call, and touches no ref, index or worktree.
`claims_branch_diff_empty` is the one word the proof will read: `true` only for `empty`, so a
degradation never licenses a delete.

Two decisions the ticket asked for, both taken and both written into the header:

- **The comparison is two diffs intersected, not one.** `merge-base..tip` alone answers
  `non_empty` forever for a branch whose content the base has since taken — measured against
  the suite's own squash-merged fixture, whose archive paths are the branch's own changes and
  are also on the base. `base..tip` alone answers `non_empty` for every path the base moved on
  without the branch. The intersection — paths this branch changed that still differ from the
  base tip — is the question.
- **Exactly one subtraction: the claim's own stamped artifacts**, the list the scan already
  carries as the row's tenth field. Measured on the reproduction, every claim branch has a
  non-empty raw diff because the claim commit writes `claim: <branch>` into its own artifacts,
  so without this subtraction no branch would ever retire. Its cost is stated rather than
  hidden: at the mission grain the stamped artifact is `mission.md`, which the archive test
  does not prove is on the base, so a mission claim that also edited its own `mission.md` and
  whose tickets landed elsewhere loses those edits — the racing-twin semantics `superseded`
  already carries.

Recorded in `drive/reference/claims.md` as a **ninth vocabulary** — a reading with its own
sub-table, naming its consumers, adding no row to the verdict table — and pinned in
`scripts/test-workflow-scripts.mjs` the way the eight before it are: the emitted set is parsed
out of the library's own `_cbd_emit` call sites, the classified set out of the table, both
directions are asserted, and no row may be called a proof.

### Discovered Insights

- **Insight**: the merge base is the wrong reference point for "does this branch hold work",
  and the suite already contained the counter-example.
  **Context**: `makeSquashMergedClaims` archives the batch's tickets on the branch and then
  squashes the branch onto the base. Those archive paths are the branch's own changes against
  the merge base, so a merge-base-only diff calls a legitimately delivered branch non-empty
  and would have refused every squash-merged retirement — the exact class of branch the
  `delete_branch_on_merge` + squash pairing produces here. The intersection form was found by
  reading that fixture before writing the term, not by a test failing afterwards.
- **Insight**: both path lists must cross the same escaping boundary.
  **Context**: `awk -v` applies escape processing to its value, and git quotes unusual paths
  with backslashes. Passing one list through `-v` and the other through stdin would transform
  only one side, so a held file with a quoted path would drop out of the intersection — and
  dropping out means reading `empty`, which is the direction that licenses a delete. Both
  lists go in through `-v`.
