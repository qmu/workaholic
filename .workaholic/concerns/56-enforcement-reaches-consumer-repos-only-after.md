---
origin_pr: 56
origin_pr_url: https://github.com/qmu/workaholic/pull/56
origin_branch: work-20260624-140219
origin_commit: e78465d
created_at: 2026-06-24T21:39:11+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Enforcement reaches consumer repos only after this release

## Description

The hooks live in the workaholic plugin; a consumer repo gains them only once this version is published and the repo updates. That repo is migrated to `workaholic@workaholic` + `autoUpdate: true`, so it will pull them post-release — but until then, in-flight branches there can still reintroduce `done/` (observed live in a consumer repo during cleanup).

## How to Fix

Ship this branch via `/release`; autoUpdate propagates the enforcement to consumer repos automatically.
