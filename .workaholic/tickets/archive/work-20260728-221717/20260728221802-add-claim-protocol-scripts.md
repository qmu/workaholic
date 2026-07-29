---
created_at: 2026-07-28T22:18:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Infrastructure]
effort: 4h
commit_hash:
category: Added
depends_on: 20260728221801-unify-mission-status-and-merge-policy.md
mission: loop-engineering-unified-drive
---

# Add the claim protocol scripts

## Overview

Execute decision G3 of `docs/loop-engineering-workflow.md`: **the repository is the coordination medium**. Before driving a unit, a runner claims it on a **pushed branch**; every runner reads the claims in flight from **unmerged remote branches**; a 5-minute tick — or a runner on another machine — never double-picks work. Run-locks are gone.

The unit and claim model (front-loaded here so the drive ticket builds on it):

- A **PR-unit** is either one approved **mission** (`unit id = mission slug`) or one **batch** of related backlog tickets (`unit id = batch-<ts>`, minted at claim time). One unit ↔ one branch ↔ one worktree ↔ one PR.
- A **claim** is a commit on a fresh `work-*` branch (cut from `origin/main`, standard creator) whose subject is `Claim <unit-id>` and whose content stamps `claim: <branch>` into the claimed artifacts' frontmatter — the mission's `mission.md`, or each batched ticket file — **pushed immediately**. The stamp is on the branch only; main never shows claims.
- The **reader** fetches, enumerates remote branches with commits not on `origin/main`, and extracts each branch's claimed unit: artifacts whose branch-tip frontmatter carries `claim: <that branch>` (with the `Claim *` subject as the fast filter). Output: `[{unit, branch, artifacts, last_commit_at}]`.
- **Release = merge or discard.** A merged branch's claims vanish from the unmerged set by definition; an abandoned unit is released by deleting its remote branch. **Staleness is reported, never auto-broken**: the reader marks claims whose branch tip is older than `WORKAHOLIC_CLAIM_STALE_HOURS` (default 24) as `stale: true` — reclaiming is a human/dispatcher decision (open item resolved as report-only for now).
- **Worktree lifecycle (I6)**: the claim writer creates the unit's worktree (`.worktrees/<unit-id>/` — reusing the mission-worktree creator; the branch inside is the claim branch); teardown happens at ship (the drive ticket wires it) or with the claim release. `/mission close` keeps only the archive move — its teardown role dissolves.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/modeling-centric-design.md` — the unit/claim/release model is stated before the scripts; the scripts implement it, never extend it silently
- `workaholic:design` / `policies/history-structures.md` — claims are commits (auditable, ordered); releases are merges/deletions, never history rewrites
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` (applies to all code work)
- `workaholic:implementation` / `policies/directory-structure.md` — scripts live in the drive skill (the executor owns coordination)
- `workaholic:operation` / `policies/operational-planning.md` — stale claims and unreachable-origin behavior are designed failure modes, not surprises

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — `claim.sh mission <slug>` / `claim.sh batch <ticket-file>...`: fetch origin; verify the unit is unclaimed (runs the reader first); create the worktree + branch (`branching/scripts/create-mission-worktree.sh` for missions — the worktree dir is the slug; a batch gets `.worktrees/<batch-id>/` via the same creator pattern); stamp `claim: <branch>` into the claimed artifacts **in the worktree checkout**; commit `Claim <unit-id>`; push -u. Output `{claimed, unit, branch, worktree_path[, reason]}` — `reason: already_claimed` names the holder. Never prompts.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the reader: fetch (tolerate offline: report `fetched: false` and read the last-known remotes); enumerate `origin/*` branches with commits not on `origin/main`; for each, read the tip's claim-stamped artifacts; emit `[{unit, branch, artifacts: [...], last_commit_at, stale}]` with `WORKAHOLIC_CLAIM_STALE_HOURS` (default 24). Pure read.
- `plugins/workaholic/skills/drive/scripts/release-claim.sh` — discard an unfinished unit deliberately: delete the remote claim branch (+ local), tear down the worktree via `cleanup-mission-worktree.sh` (uncommitted work refuses, exactly as today). Output `{released, unit, branch}`. The merge path needs no script — merging releases by definition.
- `plugins/workaholic/skills/mission/SKILL.md` + `commands/mission.md` — the worktree-lifecycle doctrine update (I6): worktrees are claim-born and ship-torn; `/mission close` keeps the archive move only (its teardown step is deleted; a lingering worktree is an in-flight or stale **claim**, surfaced by the reader, not close's business).
- `plugins/workaholic/hooks/validate-ticket.sh` — tolerate the optional `claim:` frontmatter key on tickets (no validation; branch-only by convention).
- `scripts/test-workflow-scripts.mjs` — hermetic multi-clone coverage (below; bare origin + two clones, same pattern as the extraction push tests).
- `CLAUDE.md`, `README.md` — the claim protocol paragraph updated from "designed" to "implemented", in the same change.

## Implementation Steps

1. State the unit/claim/release model in the drive SKILL (a new **Claims** section — the single home; the command ticket references it).
2. Implement `list-claims.sh` (reader first — the writer verifies through it), then `claim.sh`, then `release-claim.sh`.
3. Dissolve `/mission close`'s teardown step (docs + command; `cleanup-mission-worktree.sh` stays, called by release/ship paths).
4. Hermetic tests — bare origin, clone A and clone B: A claims mission m1 → B's reader sees `{unit: m1, branch, stale: false}` and B's `claim.sh` refuses with `already_claimed`; batch claim stamps every ticket and the reader lists all artifacts; merge simulation (fast-forward origin/main to the claim branch) empties the reader; `release-claim.sh` deletes branch + worktree; stale marking via `WORKAHOLIC_CLAIM_STALE_HOURS=0`; offline reader (`fetched: false`) still reports last-known claims.
5. Docs; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record G3/I6); verification depth ruling: hermetic multi-clone suite, per repo precedent (no live-GitHub testing — the bare-origin pattern is the fixture).

**Acceptance criteria**

- Two independent clones can never both claim one unit: the second `claim.sh` returns `already_claimed` naming the holder, purely from git state.
- Claims are invisible on main (branch-only stamps), auditable (`Claim <unit-id>` commits), and released by merge or explicit `release-claim.sh` — the reader's output reflects each transition.
- Staleness is reported (`stale: true` past the threshold), never auto-broken.
- The worktree is claim-born; `/mission close` no longer tears worktrees down; `release-claim.sh` and (next ticket) the ship path do.
- Suite/build/verify/metadata green; docs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the multi-clone claim cases; build + verify + validate-metadata green; posix-lint conforming.

**Gate**

- Suite green, and the multi-clone scenario passing end to end (claim → seen remotely → refuse double-claim → merge empties → release tears down).

## Considerations

- The claim stamp must ride the **worktree** checkout, never the main tree — the runner's main checkout stays clean for the next tick (the /propose guard depends on that).
- Do not build claim *queues* or priorities here; ordering is the executor's judgment (next ticket). This ticket is coordination only.
- An unreachable origin fails the **writer** loudly (a claim that is not pushed is not a claim) but only degrades the **reader** (`fetched: false` + last-known state) — the asymmetry is deliberate: false "unclaimed" is the dangerous error.
- Batch ids embed a timestamp (`batch-<YYYYMMDDHHMMSS>`) — unique by construction, and the worktree/branch/PR triple stays 1:1:1 with the unit.

