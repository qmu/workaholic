---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
superseded_by: git-commit-msg-hook-escapes-the
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-30T02:27:29+09:00
concern_id: git-commit-msg-hook-escapes-the
severity: low
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #59) git commit-msg hook escapes the POSIX lint gate

## Description

A git hook must be named exactly `commit-msg` (no extension), but `hooks/posix-lint.sh` only scans `*.sh`, so the hook is invisible to the gate (`plugins/workaholic/hooks/git/commit-msg`). It is POSIX by construction today, but a future bashism would not be caught.

## How to Fix

If more git-native hooks are added under `hooks/git/`, extend `posix-lint.sh` to scan that directory, or keep the extensionless hooks trivially POSIX with real logic in lintable `lib/*.sh`.
