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

# (carried from PR #67) Prompt phrasing is prose, not machine-checked

## Description

Key prompt phrasing is enforced only as prose, not machine-checked, so drift in the wording goes undetected (deferred concern `.workaholic/concerns/67-prompt-phrasing-is-prose-not-machine.md`).

## How to Fix

Add an assertion over the prompt text where the phrasing is load-bearing.
