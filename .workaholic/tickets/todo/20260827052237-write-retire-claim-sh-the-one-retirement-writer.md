---
created_at: 2026-08-27T05:22:37+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-and-retire-what-the-loop-already-proved-finished
merge_policy:
verification_handoff: 
---

# Write retire-claim.sh, the one retirement writer

## Overview

PROPOSED. `superseded` (2026-08-26) means the claim's content already reached the base — a
proof, not a suspicion. It is "reported, never acted on": `stalled-units` stops asking about
it, and `plan-units.sh` resurveys the work behind it. What nothing does is **retire the claim
itself** — its branch, its worktree and its open pull request stay forever, so the claim table
only ever grows. Measured on this repository on 2026-08-27: 7 claims, **4 of them
`superseded`**, two of those naming missions archived days ago, the oldest branch last touched
2026-08-21.

`drive/scripts/retire-claim.sh` is the one writer of that retirement: given a claim proved
`superseded`, close its pull request, delete its remote branch, reap its worktree. It merges
nothing and pushes into no branch.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the claim protocol's teardown seams

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — **new**; the one retirement writer.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the verdict it reads, and
  `claims_unit_resolution` / `claims_unit_row`, which already resolve a unit held by two
  branches to the live one; the retirement must never resolve through first-match.
- `plugins/workaholic/skills/drive/scripts/release-claim.sh` — the existing explicit-discard
  writer; read its worktree teardown and its `half_released` reporting before writing a second.
- `plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh` — the sanctioned
  worktree cleaner; compose it rather than reaping by hand.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport; closing a
  pull request is a REST write.
- `plugins/workaholic/skills/drive/reference/claims.md` — the record; retirement joins it.

## Implementation Steps

1. Read the whole of `drive/reference/claims.md`'s `superseded` record and the 2026-08-27
   two-live-claims rule before writing anything: a unit can be held by a `superseded` branch
   **and** a live one, and retiring the wrong branch would tear down live work.
2. Refuse anything that is not a proof, by name: a row whose verdict is not `superseded` is
   refused with its own verdict word, and `ambiguous_claim` and `unanswerable` are refused by
   their own names rather than folded into a generic denial.
3. Retire in an order where each step is safe alone and the whole is resumable: close the pull
   request, delete the remote branch, reap the worktree. A step that fails is reported by name
   and the remaining steps are not guessed at.
4. Make it **idempotent**: an already-closed pull request, an already-deleted branch and an
   absent worktree are each a real success, not a degradation. Re-running retires nothing twice.
5. Emit JSON naming each of the three acts and its outcome, so the caller (ticket 5) reports
   what happened rather than that something did.
6. Merge nothing, push into no branch, and touch no artifact under `.workaholic/`.
7. Record the writer in `drive/reference/claims.md` and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Given a `superseded` row: pull request closed, remote branch deleted, worktree reaped.
- Given any other verdict: refused by that verdict's own name, nothing written.
- `ambiguous_claim` and `unanswerable` each refused by their own name.
- Idempotent — a second run over the same row reports success and changes nothing.
- Nothing merged, no branch pushed into, no `.workaholic/` artifact touched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire` (ticket 7)
- Run twice over the same fixture row and diff the reported outcomes.

**Gate** — what must pass before approval:

- The unit resolution goes through `lib/claims.sh`'s live-row rule, not first-match, and every
  refusal is named.

## Considerations

- This is a destructive, outward-facing act. What makes it safe is that the verdict is a
  **proof** — the unit's content is already on the base — and the ticket refuses every
  judgement verdict by name. Do not generalise it to `stale` or `queue_drained`: acting on a
  judgement is how a run discards work another person is still driving.
- A pull request closed in error is reopenable and a deleted remote branch is recoverable from
  the base's own history; the worktree is local. State that in the header rather than relying
  on the reader knowing it.
- Prefer composing `cleanup-mission-worktree.sh` over a second reaper.
