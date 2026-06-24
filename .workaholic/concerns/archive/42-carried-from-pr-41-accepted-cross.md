---
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260528-122941
origin_commit: 0915802
created_at: 2026-06-16T08:57:05+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #41) Accepted cross-agent coupling

## Description

`core:ship` remains coupled to the `CLAUDE.md` filename via `find-claude-md.sh`. This is an accepted contract, not a remediation target, but future refactors of deploy documentation should account for the tight binding.

## How to Fix

Document the contract in `CLAUDE.md`'s Deploy section (or nearest equivalent) so deploy-doc renames are caught in review. No code change required on this branch.
