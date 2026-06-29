---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #58) (carried from PR #54) Trip unification is unproven by a live `/trip` run

## Description

The `/trip`-unification protocol — the Decomposition gate, per-ticket Coding loop, context-aware queue routing, and the design-first flow-through — is still validated only by static checks and prose review, never exercised end-to-end by a real `/trip` (see [1c8e87a](https://github.com/qmu/workaholic/commit/1c8e87a) in `plugins/workaholic/skills/trip-protocol/SKILL.md`). The flow-through change is prose-only and carries the same caveat.

## How to Fix

Run a real end-to-end `/trip` — both a design-first trip (confirm it flows through Decomposition into the per-ticket build with no pause) and a queue-execute trip (confirm routing skips Planning and drives a pre-populated queue) — before relying on the new flow.
