---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
superseded_by: collect-commits-body-emission-is-a
last_seen: 2026-06-29T13:18:46+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: collect-commits-body-emission-is-a
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #58) collect-commits body emission is a load-bearing, easily-severed link

## Description

The commit Concerns/Insights → section-reviewer wiring assumes `collect-commits.sh` emits the commit body and that the report orchestrator passes those bodies to the section worker (see [24e5b37](https://github.com/qmu/workaholic/commit/24e5b37) in `plugins/workaholic/skills/report/scripts/collect-commits.sh`). The script silently dropped the body once already; if it regresses, the new keys stop reaching `/report` with no error.

## How to Fix

Keep the `collect-commits` body-emission smoke test green, and keep the commit-bodies input wired to the section-reviewer when editing report Phase 2.
