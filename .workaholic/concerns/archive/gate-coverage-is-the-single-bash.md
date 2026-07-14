---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: gate-coverage-is-the-single-bash
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
superseded_by: commit-subject-rule-lacks-unbypassable-enforcement
---

# Gate coverage is the single-Bash-call agent surface only

## Description

Per least-privilege the `PreToolUse(Bash)` commit gate blocks off-policy subjects only (not block-all), and structurally it sees only the agent's top-level Bash command (see [24a3096](https://github.com/qmu/workaholic/commit/24a3096) in `plugins/workaholic/hooks/guard-git-commit.sh`). A human's terminal `git commit`, `--no-verify`, GitHub-web/server merges, and any non-Bash agent path are all out of scope; the opt-in 2050 `commit-msg` hook closes only the local-human gap once installed.

## How to Fix

Treat the Bash gate as one belt in a stack, not a vault: install the `commit-msg` hook for local-human coverage, and add server-side branch protection / a required status check for the remote surface the local hooks cannot reach.
