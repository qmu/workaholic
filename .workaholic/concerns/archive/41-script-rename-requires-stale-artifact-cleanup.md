---
origin_pr: 41
origin_pr_url: https://github.com/qmu/workaholic/pull/41
origin_branch: work-20260528-091259
origin_commit: b53a3a0
created_at: 2026-05-28T12:02:14+09:00
last_seen: 2026-05-28T12:02:14+09:00
first_seen: 2026-05-28T12:02:14+09:00
concern_id: script-rename-requires-stale-artifact-cleanup
severity: low
status: resolved
resolved_by_pr: 55
resolved_by_commit: 687ee82
---

# Script rename requires stale-artifact cleanup

## Description

When a bundled skill script is renamed, `build.mjs` picks up the new name automatically but does not delete the orphaned old artifact. The stale `dist/.../find-cloud-md.sh` had to be manually staged for deletion before committing, or `dist-freshness` CI would have failed (see [13f365e](https://github.com/qmu/workaholic/commit/13f365e) in `dist/workflows/skills/ship/ship/scripts/`).

## How to Fix

After regenerating `dist/` following a script rename, verify `git status -- dist/` shows the old script as deleted and explicitly stage it. Consider adding a cleanup pass to `build.mjs` to remove orphaned scripts so the manual step disappears.
