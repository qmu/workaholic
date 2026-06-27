---
origin_pr: 58
origin_pr_url: https://github.com/qmu/workaholic/pull/58
origin_branch: work-20260627-153246
origin_commit: 32110a0
created_at: 2026-06-27T23:57:36+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #54) Trip unification is unproven by a live `/trip` run

## Description

The `/trip`-unification protocol — the Decomposition gate, per-ticket Coding loop, context-aware queue routing, and now the design-first flow-through added here ([1c8e87a](https://github.com/qmu/workaholic/commit/1c8e87a)) — is still validated only by static checks and prose review, never exercised end-to-end by a real `/trip`. This branch's flow-through change is prose-only and carries the same caveat.

## How to Fix

Run a real end-to-end `/trip` — both a design-first trip (confirm it flows through Decomposition into the per-ticket build with no pause) and a queue-execute trip (confirm routing skips Planning and drives a pre-populated queue) — before relying on the new flow.
