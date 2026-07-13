---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
last_seen: 2026-06-17T01:51:15+09:00
first_seen: 2026-06-17T01:51:15+09:00
concern_id: spec-relative-cross-skill-references-remain
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #42) Spec-relative cross-skill references remain fragile

## Description

Cross-skill `${SCRIPT_DIR}` references must use the full literal form or they ship broken; verified correct in this merge via smoke tests, but the fragility persists for future changes (see `.workaholic/concerns/42-spec-relative-cross-skill-references-can.md`).

## How to Fix

Keep `verify.mjs` mandatory after any cross-skill ref change; consider a lint rule flagging short relative skill paths.
