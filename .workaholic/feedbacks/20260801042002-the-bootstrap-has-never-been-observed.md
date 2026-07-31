---
type: Feedback
title: The bootstrap has never been observed working on the web
kind: concern
source: development
created_at: 2026-08-01T04:20:02+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-bootstrap-has-never-been-observed
owner: 
mission: []
tickets: [20260801030421-workaholify-provisions-the-loop-engineering-environment.md]
origin_pr: 138
origin_pr_url: https://github.com/qmu/workaholic/pull/138
origin_branch: work-20260801-033154
origin_commit: 2c2db915
last_seen: 2026-08-01T04:20:02+09:00
---

# The bootstrap has never been observed working on the web

## Description

The hook is verified by its contract (POSIX, fail-open, idempotent, correct flags) and is a no-op locally by construction — but no test can exercise the path that matters, because that path only exists inside a Claude Code Web container. Issue #126 lists two platform facts still unconfirmed: whether sandbox git can clone a *different* private repo than the session's own, and the actual `claude plugin install` flag set.

## How to Fix

The next hourly `[Drive]` run is the observation. Read `${TMPDIR}/bootstrap-workaholic.log` in that session, or watch whether the run stops at its plugin precondition. Until then this is unproven, not proven.
