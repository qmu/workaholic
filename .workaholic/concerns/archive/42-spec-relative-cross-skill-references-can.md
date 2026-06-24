---
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
created_at: 2026-06-16T08:57:05+09:00
severity: moderate
status: resolved
resolved_by_pr: 55
resolved_by_commit: 63da753
---

# Spec-relative cross-skill references can ship broken

## Description

Cross-skill script references must use the full `${SCRIPT_DIR}/../../../../core/skills/.../scripts/` form with literal uppercase `SCRIPT_DIR` for the dist build's regex to detect and copy the closure. Shorter relative forms resolve in source but are invisible to the build and ship broken to Codex and the `skills` CLI (see commit 9aab12d Final Report, `scripts/build-plugins/build.mjs`).

## How to Fix

Audit new cross-skill references against `SCRIPT_CROSS_REF` in `build.mjs`, always use the full literal-`SCRIPT_DIR` form, and run `node scripts/build-plugins/verify.mjs` after adding any cross-skill call.
