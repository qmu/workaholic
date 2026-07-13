---
origin_pr: 58
origin_pr_url: https://github.com/qmu/workaholic/pull/58
origin_branch: work-20260627-153246
origin_commit: 32110a0
created_at: 2026-06-27T23:57:36+09:00
last_seen: 2026-06-29T13:18:46+09:00
first_seen: 2026-06-27T23:57:36+09:00
concern_id: collect-commits-body-emission-is-a
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# collect-commits body emission is a load-bearing, easily-severed link

## Description

The new commit Concerns/Insights → section-reviewer wiring assumes `collect-commits.sh` emits the body and that the report orchestrator passes the commit bodies to that worker (see [24e5b37](https://github.com/qmu/workaholic/commit/24e5b37) in `plugins/workaholic/skills/report/scripts/collect-commits.sh`). The script silently dropped the body once already; if it regresses, the new keys stop reaching `/report` with no error.

## How to Fix

Keep the `collect-commits` body-emission smoke test green, and keep the commit-bodies input wired to the section-reviewer when editing report Phase 2.
