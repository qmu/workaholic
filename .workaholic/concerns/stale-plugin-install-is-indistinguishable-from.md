---
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
created_at: 2026-07-01T01:12:10+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T01:12:10+09:00
concern_id: stale-plugin-install-is-indistinguishable-from
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Stale plugin install is indistinguishable from a broken hook

## Description

A stale plugin install presents an absent hook identically to a broken one (see [56cf7a0](https://github.com/qmu/workaholic/commit/56cf7a0)). Hook presence in `hooks.json` is checkable from a script, but activation is not — a PreToolUse hook fires on the Bash *tool* call, not nested `sh` (`plugins/workaholic/skills/check-deps/scripts/check.sh`).

## How to Fix

The `check-deps` version surfacing ([5059220](https://github.com/qmu/workaholic/commit/5059220)) is the durable mitigation; the in-session activation probe is documented in `check-deps/SKILL.md` so agents can distinguish presence from activation.
