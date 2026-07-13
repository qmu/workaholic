---
origin_pr: 44
origin_pr_url: https://github.com/qmu/workaholic/pull/44
origin_branch: work-20260617-082241
origin_commit: ba49fe6
created_at: 2026-06-17T20:14:03+09:00
last_seen: 2026-06-17T20:14:03+09:00
first_seen: 2026-06-17T20:14:03+09:00
concern_id: spec-relative-cross-skill-references-can
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# (carried from PR #42) Spec-relative cross-skill references can ship broken

## Description

Cross-skill script references must use the full `${SCRIPT_DIR}/../../../../<skill>/scripts/` form with literal uppercase `SCRIPT_DIR` for the dist build's regex to detect and copy the closure. Shorter relative forms resolve in source but are invisible to the build and ship broken to Codex and the `skills` CLI (`scripts/build-plugins/build.mjs`).

## How to Fix

Audit new cross-skill references against `SCRIPT_CROSS_REF` in `build.mjs`, always use the full literal-`SCRIPT_DIR` form, and run `node scripts/build-plugins/verify.mjs` after adding any cross-skill call.
