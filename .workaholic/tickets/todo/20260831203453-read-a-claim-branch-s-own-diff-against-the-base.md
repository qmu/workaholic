---
created_at: 2026-08-31T20:34:53+00:00
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
