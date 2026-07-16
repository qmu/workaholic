---
type: Concern
concern_id: a-pretooluse-hook-cannot-know-its
mission: []
tickets: [20260715121047-confine-writes-to-current-repo.md, 20260715121048-request-command-cross-repo-tickets.md, 20260715121049-remove-dead-leak-rule.md, 20260715121050-secret-pattern-misses-suffixed-keywords.md, 20260715132431-secret-scan-flags-type-annotations.md, 20260715143954-mission-relation-many-valued.md, 20260715163311-mission-lens-says-less.md, 20260715181934-invert-secret-pass2-to-match-values.md]
origin_pr: 86
origin_pr_url: https://github.com/qmu/workaholic/pull/86
origin_branch: work-20260715-112717
origin_commit: 12320d10
created_at: 2026-07-15T20:55:56+09:00
first_seen: 2026-07-15T20:55:56+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# A PreToolUse hook cannot know its caller, so per-skill exceptions are unimplementable

## Description

The confinement guard blocked `/explain`'s export the day it landed, and neither ticket mentioned the other ([ef80cd64](https://github.com/qmu/workaholic/commit/ef80cd64)). No exception was possible: a `PreToolUse` hook sees only `tool_input.file_path`, so an `.html` bound for Home is indistinguishable from any other write there. The staging file moved rather than the gate widening, because this hook is currently the only *hook* refusing a Write to `/etc` or `~/.claude` — system-safety is prose, not a gate.

## How to Fix

Remember the constraint: the choice is to move the write or widen the gate for everyone. The characterization test `confine blocks a non-repo path outside the repo (export dir)` pins it deliberately.

