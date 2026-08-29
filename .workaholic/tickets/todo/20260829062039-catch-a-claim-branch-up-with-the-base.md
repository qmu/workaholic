---
created_at: 2026-08-29T06:20:39+00:00
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
