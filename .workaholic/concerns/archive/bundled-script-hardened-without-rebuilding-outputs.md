---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: bundled-script-hardened-without-rebuilding-outputs
severity: moderate
status: resolved
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Closed by the Outputs Freshness CI workflow, which rebuilds and runs git diff --exit-code over outputs/ on every PR touching plugins/**, so a bundled-skill edit without a rebuild cannot reach main. Verified: build at HEAD leaves outputs/ clean.
closed_at: 2026-07-15T19:50:28+09:00
---

# Bundled script hardened without rebuilding outputs/, leaving the public copy stale

## Description

Ticket 2047 hardened `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh`, which is a **bundled** branching-skill script in the drive/report/ship/create-ticket closure, but its archival commit ([24a3096](https://github.com/qmu/workaholic/commit/24a3096)) claimed "No outputs/ rebuild" — the `outputs/` copies were left stale and only regenerated later during the version bump ([1f7c620](https://github.com/qmu/workaholic/commit/1f7c620)), so source and artifact were out of lockstep in between (an `Outputs Freshness` CI failure waiting to happen).

## How to Fix

When editing any script under a bundled skill closure, always run `node scripts/build-plugins/build.mjs` and commit `outputs/` in lockstep within the same change; only pure `hooks/` changes may skip the rebuild. Treat "is this script in a shipped closure?" as a checklist item before claiming "No outputs/ rebuild."
