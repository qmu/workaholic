---
created_at: 2026-07-22T08:14:05+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# Worktree cleanup must never delete the default branch

## Overview

`branching/scripts/cleanup-mission-worktree.sh` deletes the branch the removed worktree was checked out on — whatever that branch is. Two sanctioned flows compose into data loss: `/ship` run inside a mission worktree ends with `merge-pr.sh` checking out `main` **in that worktree**, so a later `/mission close` teardown removed the local **`main`** branch (observed 2026-07-22 closing `reorganize-missions-under-strategies`; recovered from `origin/main` via `git fetch origin main:main` — the branch guard blocks `git branch main`, so recovery is non-obvious too). Nothing was lost only because everything had been pushed.

Decided at ticket time (decide-and-record): the guard belongs in the **cleanup script** — delete the branch only when its name matches the sanctioned ephemeral pattern `work-YYYYMMDD-HHMMSS`; any other name (`main`, a drive-era branch, anything hand-made) is left alone with the skip reported in the JSON. Re-pointing `merge-pr.sh` away from parking worktrees on `main` is deliberately **out of scope** (it would change `/ship` semantics for every context); a Considerations note may record it as a possible follow-up.

## Policies

- **Implementation / observability** — the script's JSON must state what it did *and did not* do: report `branch_removed: false` with a `branch_kept_reason` (e.g. `not-work-branch`) instead of silently skipping.
- **Safety floor (drive Night Mode)** — "never destructive git" extends to the scripts agents run; deleting a non-ephemeral branch is destructive by definition.
- **Shell Script Principle / POSIX** — the guard lives in the script (`#!/bin/sh -eu`), not in caller prose.

## Key Files

- `plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh` — add the branch-name pattern check before the `git branch -D`; keep worktree removal unconditional (the worktree itself is always safe to remove once close.sh succeeded).
- `scripts/test-workflow-scripts.mjs` — hermetic fixtures (see Quality Gate).
- `outputs/workflows/` — the script rides the build closure into create-ticket/drive/report built skills; regenerate with argument-less `node scripts/build-plugins/build.mjs` and commit the diff.

## Related History

- Mission-worktree model introduced on `work-20260714-000543` (cleanup created there); `/ship`-inside-worktree leaving the worktree on `main` comes from `merge-pr.sh`'s checkout-main-and-pull step.

## Implementation Steps

1. In `cleanup-mission-worktree.sh`, read the worktree's branch before removal; after removing the worktree, delete the branch only if it matches `work-[0-9]{8}-[0-9]{6}`; otherwise emit `branch_removed: false` and a `branch_kept_reason`.
2. Add hermetic tests; rebuild `outputs/`; run the verification suite.

## Quality Gate

- `node scripts/test-workflow-scripts.mjs` green, with new fixtures: (a) worktree on a `work-*` branch → worktree and branch both removed (current behavior preserved); (b) worktree on `main` → worktree removed, `main` survives, JSON reports the kept branch with its reason; (c) worktree on a non-pattern branch → same as (b).
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` empty at commit; `verify.mjs` and `validate-metadata.mjs` pass.
- JSON output remains backward-compatible (existing keys unchanged; additions only).

## Considerations

- Possible follow-up (not this ticket): have `/ship` re-branch a mission worktree after merge instead of leaving it parked on `main`, mirroring the trip flow's worktree re-branching.
