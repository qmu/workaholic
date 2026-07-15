---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: commit-is-an-escape-hatch-that
severity: low
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: The steering copy the concern asked for is in place (commands/commit.md:15 and CLAUDE.md's command table both say prefer /drive for ticketed work). An escape hatch existing is a deliberate trade-off; the remaining action was monitoring, not a fix.
closed_at: 2026-07-15T19:50:28+09:00
---

# /commit is an escape hatch that can invite non-ticketed commits

## Description

The new `/commit` command provides a sanctioned path for ad-hoc commits, but by existing it can normalize committing outside the ticketed `/drive` flow (see [a62d99c](https://github.com/qmu/workaholic/commit/a62d99c) in `plugins/workaholic/commands/commit.md`). It is still strictly better than free-handed `git commit` because both the command and the gate preserve the message policy.

## How to Fix

Keep the command copy steering users to `/drive` for ticketed work and framing `/commit` as for small/explicit non-ticketed changes; revisit if commit history shows `/commit` displacing ticketed development.
