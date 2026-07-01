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

# --prune mutates the user's remote-tracking refs on every /catch

## Description

The fetch uses `--prune` to drop remote-tracking refs for upstream-deleted branches so the report shows no ghosts, but this means every `/catch` run silently mutates `refs/remotes/*` in the user's clone — a side effect a user of a nominally read-only report may not expect (see [ad4ea8d](https://github.com/qmu/workaholic/commit/ad4ea8d) in `plugins/workaholic/skills/catch/scripts/scan-window.sh`; ticket Considerations "--prune is a deliberate choice").

## How to Fix

Keep the corrected read-only wording in the SKILL intro prominent, and consider making `--prune` opt-in if the ghost-branch risk proves rare in practice.
