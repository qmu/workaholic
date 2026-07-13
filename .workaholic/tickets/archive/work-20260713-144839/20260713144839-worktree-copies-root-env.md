---
created_at: 2026-07-13T14:48:39+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 0.25h
commit_hash: 847b012
category: Added
depends_on:
mission:
---

# ensure-worktree.sh copies the root repository's .env into new worktrees

## Overview

Developer directive (2026-07-13, during plgg PoC 4): development
credentials live in ONE git-ignored `.env` at each repository's root
(the plgg side — a committed `.env.example` plus the canonical runner
sourcing the root file — shipped as plgg ticket
`20260713144522-root-env-file-for-credentials.md`). The reason the file
sits at the repo root is THIS protocol: hosts run several parallel
worktrees under `.worktrees/`, and worktree creation must copy the root
repository's `.env` into each new worktree so every worktree starts with
working credentials. `.env` is git-ignored, so `git worktree add` alone
never brings it along.

## Key Files

- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` - the
  single worktree-creation protocol (trips and drives both route through
  it); the copy belongs immediately after its `git worktree add`

## Implementation Steps

1. In `ensure-worktree.sh`, after `git worktree add -b … HEAD`: if
   `"${repo_root}/.env"` exists, copy it to `"${worktree_path}/.env"`.
   Note: when invoked from inside an existing worktree, `git rev-parse
   --show-toplevel` already IS that worktree's root, whose `.env` was
   itself copied at creation — the chain still originates at the root
   repository.
2. Keep the JSON output contract unchanged (tools parse it); the copy is
   silent on success and must not fail the creation when the source
   `.env` is absent.

## Quality Gate

- With a `.env` in the repo root, a fresh `ensure-worktree.sh
  work-YYYYMMDD-HHMMSS` produces a worktree containing an identical
  `.env`.
- Without a root `.env`, creation succeeds exactly as before and the new
  worktree has no `.env`.
- The emitted JSON is byte-identical in shape to today's.

## Considerations

- `cp` must not be the interactive alias (`cp -i`) — use `cp` inside the
  non-interactive script (no alias expansion in `sh`), and copy by
  explicit source/dest paths only.
- Do NOT symlink: worktrees may diverge credentials later on purpose; a
  copy keeps them independent.
