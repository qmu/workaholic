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

Development completed as planned. The **verdict word** of this reading had already landed with
the repair (2026-09-01, issue #788); what was missing were the two halves of step 2 that make
the reading usable by anything but the verdict — **the files** and **the reason**.

- `claims_branch_emptiness <base> <ref> [files]` is now the one derivation and prints
  `<verdict>\t<reason>\t<count>\t<bounded comma-joined list>`.
  `claims_branch_empty_against_base` is a thin wrapper returning the first field, so **every
  existing caller reads exactly what it read before** — the verdict path did not move.
- **The reason is named** for every way the reading can fail to be made: `no_args`, `no_ref`,
  `no_base_ref`, `no_merge_base` (a shallow clone and an unrelated history both land here) and
  the new `diff_failed`. That last one is a narrowing: `git diff --quiet` exits 1 for *differs*
  and >1 for *failed*, and the old code collapsed both into `false`. Both still route to
  `stranded`, so nothing about safety moved; what changed is that a git failure is no longer
  reported to a person as *this branch holds work* when nothing established that it does.
- **The file list is bounded** at `WORKAHOLIC_CLAIM_STRANDED_FILES_MAX` (default 5) with the
  **true count** beside it, so a branch differing in a thousand files reports a count and a few
  names rather than a thousand names into a Slack question.
- **Nothing is subtracted beyond `:(exclude).workaholic`** (step 3), and the header says so
  rather than subtracting paths on a hunch. That one exclusion is not a convenience: the
  ordinary `superseded` shape is a twin branch that archived the same tickets under its own
  `archive/<branch>/` directory, so the two trees differ there by construction and a bare diff
  would call every genuinely superseded claim stranded.
- Exit 0 in every case, including every degradation (step 4).
- Recorded in `drive/reference/claims.md` as a **reading** with its consumers named, adding no
  row to the verdict table (step 5).

### Discovered Insights

- **Insight**: The file listing had to be made **opt-in** rather than always computed. Measured
  on a throwaway repository, 50 readings of a non-empty branch: 373 ms for the raw derivation,
  553 ms through the wrapper, and **1484 ms with the listing** — a second full `git diff` per
  call. The verdict path runs once per claim on every scan and never needs the names, so only
  `list-claims.sh`, for a `stranded` row alone, asks for them.
  **Context**: A later change that makes the listing unconditional "for simplicity" would
  triple the cost of the claim scan's most frequent reading to serve one consumer that fires
  on a handful of rows.
- **Insight**: A shallow clone answers `no_merge_base`, not a distinct `shallow` reason —
  `git merge-base` simply cannot walk to a common ancestor across the graft boundary. The
  hermetic row proves the fixture really is shallow (`git rev-parse --is-shallow-repository`)
  before asserting the answer, because a fixture that quietly stopped being shallow would keep
  passing while testing nothing.
  **Context**: The routines run in exactly this shape, so it is the case where a wrong `true`
  would be most expensive.
