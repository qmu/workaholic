---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
severity: moderate
status: resolved
resolved_by_pr: 49
resolved_by_commit: e390172
---

# apply-carryover-verdicts.sh silently skips `{"verdicts": [...]}` input

## Description

`apply-carryover-verdicts.sh` expects a **bare JSON array**, but the report skill's documented Phase 1 schema and the carry-over judge produce `{"verdicts": [...]}`. Its `python3` then iterates dict keys and processes nothing — so RESOLVED verdicts are never archived. This silently defeated carry-over resolution in the PR #42 and #43 reports and is a root cause of the concern-dir bloat (`plugins/workaholic/skills/report/scripts/apply-carryover-verdicts.sh`).

## How to Fix

Make the script accept both `{"verdicts": [...]}` and a bare array (or fix the orchestrator/skill to write the bare `.verdicts` array), and add a smoke test so this can't regress silently.
