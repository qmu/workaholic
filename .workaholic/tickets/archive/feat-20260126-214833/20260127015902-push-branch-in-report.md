---
created_at: 2026-01-27T01:59:02+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 03f7946
category: Added
---

# Push branch to remote during /report command

## Overview

The `/report` command should ensure the branch is pushed to remote before creating/updating the PR. Currently `gh pr create` can fail if the branch hasn't been pushed yet.

## Key Files

- `plugins/core/commands/report.md` - Add push step before PR creation

## Implementation Steps

1. Add step 6 (before PR creation): Push branch to remote with `git push -u origin <branch-name>`
2. Renumber current step 6 (PR creation) to step 7
3. Use `--force-with-lease` to handle force pushes safely if needed

## Considerations

- Push should happen after all documentation commits are complete
- Using `-u` sets upstream tracking for new branches
- `--force-with-lease` is safer than `--force` for updated branches

## Final Report

Development completed as planned.
