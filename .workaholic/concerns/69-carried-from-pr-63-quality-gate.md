---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #63) Quality gate is prose-mandated, not hook-enforced

## Description

The quality gate is mandated only in prose, not enforced by a hook, so it can be skipped without an automated failure (deferred concern `.workaholic/concerns/63-quality-gate-is-prose-mandated-not.md`).

## How to Fix

Back the quality gate with a machine check where feasible.
