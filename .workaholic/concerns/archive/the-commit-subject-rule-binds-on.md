---
type: Concern
concern_id: the-commit-subject-rule-binds-on
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
status: superseded
resolved_by_pr: 
resolved_by_commit: 
superseded_by: closing-the-default-commit-path-routes
---

# The commit-subject rule binds on no path — including the sanctioned one

## Description

Every bypass surface is open — `guard-git-commit.sh` allows `git commit -F file` (it only inspects an inline `-m`), the git-native `commit-msg` is opt-in via `core.hooksPath` and is not installed even in this repo, `--no-verify` waives it by design, and there is no server-side check. Read alone that is tolerable, since the sanctioned path is assumed correct-by-construction. That assumption is false: `commit.sh` — the script `/commit` and `/drive`'s `archive.sh` both route through — performs no subject validation and never calls `check-subject.sh`, and the guard deliberately exempts script-wrapped commits. The default path is the largest unguarded surface. Measured, not argued: commit [e3366bfd](https://github.com/qmu/workaholic/commit/e3366bfd) on this branch carries a 52-character subject that `commit.sh` accepted silently, and `check-subject.sh` rejects that same string when driven directly.

## How to Fix

Call `check-subject.sh` at the top of `commit.sh` and fail non-zero. One line; it closes the default path without touching either guard. The remaining bypasses are a deliberate belt-not-vault stance; an unbypassable surface needs a server-side required status check, which is a rollout decision, not a code fix.
