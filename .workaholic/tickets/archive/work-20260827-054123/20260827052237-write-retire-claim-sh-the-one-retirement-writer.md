---
created_at: 2026-08-27T05:22:37+00:00
status: done
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

## Final Report

Development completed as planned.

`drive/scripts/retire-claim.sh` is the one retirement writer. It resolves the unit through
`claims_unit_resolution` / `claims_unit_row` — the live-row rule, never first-match — which the
ticket named as the gate, and which matters here more than anywhere else it is used: a unit held
by a `superseded` branch and a live one is exactly what a fresh claim over a superseded one
creates, and first-match returns the oldest, so retiring on it would tear down whichever branch
sorted first regardless of which is alive.

Refusals are named individually as required: `not_superseded:<verdict>` carries the verdict's own
word, and `ambiguous_claim` and `unanswerable:<reason>` are separate. The unanswerable case
needed the lookup's own record — `CLAIMS_UNANSWERED_FILE`, which `list-claims.sh` already uses —
because such a branch keeps whatever verdict the local read gave it, so a plain
`not_superseded:queue_drained` would send a reader to a claim that looks live rather than to the
lookup that failed.

The three acts run in the ticket's order (close, delete, reap), each idempotent and each
reporting its own word, with `already_closed` / `already_gone` / `absent` as successes rather
than degradations. Verified by hand against three live claims on this repository: a nonexistent
unit, a `queue_drained` unit and this run's own `claim_active` unit were each refused by name
with nothing touched, and a repeated run reported identically.

### Discovered Insights

- **Insight**: The refusal path must not report `failed` or `absent` for acts it never attempted.
  **Context**: The first draft reused the success vocabulary on refusal, so a refused retirement
  reported `remote_branch_deleted: failed` — a finding about the world made by a gate that never
  looked. `not_attempted` is a fourth value on each of the three fields, and it is what lets the
  caller (ticket 5) report what happened rather than assert something it was never told.

- **Insight**: This script's step order is the *reverse* of `release-claim.sh`'s, and the reason
  is the difference between the two acts rather than a preference.
  **Context**: `release-claim.sh` discards **unfinished** work, so it tears the worktree down
  first and must never publish "this unit is free" over unpushed commits. A `superseded` claim
  has no such work by construction, and its local reap is the one step refusable for a reason
  outside the runner's control (the cleaner refuses a dirty tree, and must) — so putting the reap
  last leaves a refusal there with both remote facts already correct and a re-run finishing the
  job. Copying the existing order would have been the wrong half to lose.

- **Insight**: `CLAIMS_FETCH_OK` must be set after `claims_fetch`, or a mission-grain claim never
  reads `superseded` at all.
  **Context**: `claims_fetch` runs inside a command substitution, so the flag it sets dies with
  the subshell; without it the merged-pull-request lookup is skipped `offline`, and a mission
  claim — whose only proof of supersession is that lookup — falls back to a judgement verdict.
  The script would then refuse the exact verdict it exists to act on. `claim.sh` and
  `release-claim.sh` both carry the same line for the same reason.
