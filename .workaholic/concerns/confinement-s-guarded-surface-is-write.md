---
type: Concern
concern_id: confinement-s-guarded-surface-is-write
mission: []
tickets: [20260715121047-confine-writes-to-current-repo.md, 20260715121048-request-command-cross-repo-tickets.md, 20260715121049-remove-dead-leak-rule.md, 20260715121050-secret-pattern-misses-suffixed-keywords.md, 20260715132431-secret-scan-flags-type-annotations.md, 20260715143954-mission-relation-many-valued.md, 20260715163311-mission-lens-says-less.md, 20260715181934-invert-secret-pass2-to-match-values.md]
origin_pr: 86
origin_pr_url: https://github.com/qmu/workaholic/pull/86
origin_branch: work-20260715-112717
origin_commit: 12320d10
created_at: 2026-07-15T20:55:56+09:00
first_seen: 2026-07-15T20:55:56+09:00
last_seen: 2026-07-15T20:55:56+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Confinement's guarded surface is Write/Edit only; Bash and MCP cross freely

## Description

`guard-repo-confinement.sh` is a `PreToolUse(Write|Edit)` hook, so a Bash redirect crosses a repository boundary freely (it is how `file-request.sh` itself writes), and MCP writes are likewise unseen — which is what keeps `/explain`'s browser-printed PDF working ([ef80cd64](https://github.com/qmu/workaholic/commit/ef80cd64)). The threat model is deliberate, but `rules/general.md` still reads "never target a path outside `git rev-parse --show-toplevel`", describing the Write surface as if it were universal.

## How to Fix

State the asymmetry in `rules/general.md` and the hook header — the guard covers Write/Edit, the rule covers intent, neither claims Bash or MCP. Do **not** grow the hook toward content matching.
