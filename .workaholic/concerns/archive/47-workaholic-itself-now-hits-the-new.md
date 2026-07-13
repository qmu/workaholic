---
origin_pr: 47
origin_pr_url: https://github.com/qmu/workaholic/pull/47
origin_branch: work-20260617-210627
origin_commit: 6a64cf0
created_at: 2026-06-17T22:08:29+09:00
last_seen: 2026-06-17T22:08:29+09:00
first_seen: 2026-06-17T22:08:29+09:00
concern_id: workaholic-itself-now-hits-the-new
severity: moderate
status: resolved
resolved_by_pr: 48
resolved_by_commit: 066714b
---

# Workaholic itself now hits the new `/ship` halt path (dogfooding gap)

## Description

The new gate (see [80e721c](https://github.com/qmu/workaholic/commit/80e721c)) requires a documented confirmation method, but this repo has no real `.workaholic/deployments/` target entry (only the README template) and no `CLAUDE.md ## Deploy`/`## Verify` section. So `read-deployments.sh` returns `has_confirmation: false` and `/ship` on workaholic itself will halt at §1-4. This is the gate working as designed (it halts rather than silently skipping) and was explicitly deferred by the branch's tickets — but it must be resolved before the next clean `/ship`.

## How to Fix

Author the repo's own deployment contract — either a `.workaholic/deployments/` entry stating a trivial confirmation ("the merge to `main` is the deployment; confirm the release commit/tag is on `main`") or a `## Verify` section in `CLAUDE.md`.
