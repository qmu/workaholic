---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #41) Accepted cross-agent coupling

## Description

`core:ship`'s coupling to the `CLAUDE.md` filename (via `find-claude-md.sh`) is unchanged; an accepted contract, not a bug (see `.workaholic/concerns/41-accepted-cross-agent-coupling.md`).

## How to Fix

Document it as an intentional boundary in the pending standards narrative rewrite. No code change.
