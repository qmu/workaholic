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

# Catch a claim branch up with the base

## Overview

PROPOSED. The writer: merge the base into the claim head inside the unit's own worktree,
regenerate generated files with the repository's own tooling, run the repo's fast checks,
push. One act, idempotent, exit 0 on every path, and **nothing written on any refusal**.

**Most of it already exists.** `ship/scripts/catchup-main.sh` performs the merge, resolves
append-only `.workaholic/` conflicts by shape, classifies the rest, and aborts so the caller
acts from a clean tree; `land-unit.sh` composes it. What is missing is a caller an unattended
run can reach: `land-unit.sh` refuses `headless_context` first and unoverridably, by design.
So this is a **composition with the claim protocol's bounds**, not a new merge engine — it
must not re-derive the classification or the append-only resolution.

The worktree seam is `create-mission-worktree.sh --branch <existing-work-branch>`, which
attaches to a published branch; `ensure-worktree.sh` refuses a name already on origin, which
is correct and must not be worked around.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — composed, never re-derived.
- `plugins/workaholic/skills/drive/scripts/land-unit.sh` — the existing composition to follow
  for order and refusal shape; read why it refuses headless before diverging from it.
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` — `--branch` resume
  mode, the only sanctioned way to attach a worktree to a published claim branch.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — identity, the live-row rule, and
  the verdict this re-derives at the moment of the act.
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` — the scan whose
  `hard`/`confirm` tiers make a pull request untouchable here.

## Implementation Steps

1. Resolve the unit through `lib/claims.sh`'s **live-row rule**, never first-match, and
   re-derive the verdict at the moment of the act rather than trusting a list handed in.
2. Refuse, each by its own word, writing **nothing**: `content_conflict`, `not_my_claim`,
   `foreign_identity`, `dirty_worktree`, `scan_held:<tier>`, `not_a_work_branch`. Every path
   exits 0.
3. Attach or reuse the worktree through `create-mission-worktree.sh --branch`.
4. Compose `catchup-main.sh` for the merge and the classification. Never a rebase, an amend
   or a force-push — a merge commit keeps the claim holder's checkout valid, which is the
   protocol's existing rule and the reason `step-merge-conflicts.sh` refuses to rebase.
5. Regenerate generated files with the repository's own tooling (`node
   scripts/build-plugins/build.mjs`), never by hand.
6. Run the repo's fast checks (`verify.mjs`, `validate-metadata.mjs`,
   `test-workflow-scripts.mjs`) and refuse the push if any fails, leaving the branch unpushed.
7. Push. An already-current branch reports `already_current` and touches no ref.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every refusal is named, writes nothing, and exits 0; the branch is byte-identical after one.
- Never a rebase, an amend or a force-push, on any path.
- A scan-held pull request is never caught up — the catch-up is not a route around a gate.
- A colleague's claim is untouched at any age.
- Idempotent: a second run on a current branch reports `already_current` and pushes nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- The ticket-1 fixture, driven through this writer for each refusal and for the success path.

**Gate** — what must pass before approval:

- Each of the six refusals is exercised and each leaves the fixture branch byte-identical.

## Considerations

This narrows a standing rule rather than reversing it. `step-merge-conflicts.sh`'s header
refuses to rebase because a third party rebasing a claim branch races the holder's own pushes
and can strand or duplicate a unit. Both halves of that reasoning are answered here — the
claim is **this identity's own**, and the act is a **merge**, not a history rewrite — and
neither may be quietly widened. The genuinely contested case stays with a person.

## Final Report

Development completed as planned. `drive/scripts/catch-up-claim.sh <unit>` composes
`ship/scripts/catchup-main.sh` with the claim protocol's bounds. It resolves the unit through
`lib/claims.sh`'s live-row rule, re-derives the verdict at the moment of the act, refuses each
bound by its own word writing nothing, attaches the worktree through
`create-mission-worktree.sh --branch` (never working around `ensure-worktree.sh`'s refusal),
merges, regenerates, validates and pushes. Every path exits 0.

Refusals, each named: `content_conflict`, `not_my_claim`, `foreign_identity`,
`identity_unresolved`, `claim_active`, `dirty_worktree`, `scan_held:<tier>`,
`not_a_work_branch`, `ambiguous_claim`, `mergeability_unanswerable:<reason>`, plus the
composition's own (`no_such_claim`, `no_origin`, `origin_unreachable`, `catchup_<class>`,
`validation_failed:<check>`, `push_failed`). Never a rebase, an amend or a force-push, on any
path — asserted from the source by the suite.

**Two things had to change beyond the plan, and both are stated rather than absorbed.**

1. `catchup-main.sh` gained an opt-in `--resolve-mechanical`. Its existing contract classifies
   a mechanical remainder and *aborts*, because "routine reconciliation the agent performs
   itself" was written for a caller with an agent in it. This caller has none, so the flag
   resolves what needs no judgement — a generated path by taking a side (which side is
   immaterial; the content is derived), a version manifest by raising both sides to the higher
   semver and merging normally, so a side that also added a plugin keeps that addition. Taking
   one side wholesale was rejected for exactly that reason. Without the flag the script is
   byte-for-byte what it was, which is what `land-unit.sh` still gets.
2. `retry-undelivered.sh` gained `--own-tip`. The fixture proved it must change: the catch-up's
   own push makes the tip fresh, so the very next verdict reads `claim_active` and the delivery
   the catch-up exists to unblock is refused by the act that unblocked it. The flag relaxes
   **one term** and does so by re-asking the same oracle with
   `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0` — identity, ancestry, supersession, the drained
   fork and the recorded refusal all stay the oracle's own answers, computed in one place.
   Nothing is re-derived, no verdict is widened, and the scan-held refusal is unchanged (the
   suite asserts a `merge_not_attempted: hard` unit is refused with the flag exactly as
   without it).

The standing rule is **narrowed, not reversed**: `step-merge-conflicts.sh` refuses to rebase
because a third party racing the holder's pushes can strand a unit. Both halves are answered —
the claim is this identity's own, and the act is a merge rather than a history rewrite — and
`claim_active` answers the race the rule is really about, so only a branch nothing is
committing to is touched. `claim_active` is checked *after* the `already_current` early return
and *before* the first act: reporting a no-op protects nothing.

Proved live as well as hermetically: on the real stranded branch `work-20260826-134108` the
writer resolved all six conflicts, the version collision converged on the higher semver, and
`refresh-index.sh` + `build.mjs` + `verify.mjs` came back clean.

### Discovered Insights

- **Insight**: A push is a heartbeat, so any maintenance act on a claim branch makes that claim
  read `claim_active` to the very next reader.
  **Context**: Every future act on a claim branch that is not a drive will hit this. The pattern
  that works is to re-ask the oracle with the liveness window collapsed rather than to bypass
  the gate — the other terms stay derived in one place.
- **Insight**: `git merge-file` with a normalising pre-pass resolves a version collision without
  choosing a side.
  **Context**: Raising both sides to the higher semver removes the only hunk that conflicts and
  lets everything else merge normally, so a branch that also edited the manifest keeps its edit.
