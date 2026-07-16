---
type: Concern
concern_id: deferred-concern-severity-has-no-re
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
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163003-concern-machinery-robustness.md (2026-07-16 triage-to-zero): add a re-grade.sh in-place severity mutator. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:47+09:00
---

# Deferred-concern severity has no re-grade mutator

## Description

`merge-concerns.sh` escalates severity only when forming a compound and `close-concern.sh` archives; nothing edits severity in place, so PR #86's urgent → moderate re-grade had to be a hand edit against the README's never-hand-edit rule ([9d81dd3a](https://github.com/qmu/workaholic/commit/9d81dd3a)). This concern also carries a self-correction on its own record: an earlier dismissal of a provenance-less compound as "a data defect from before identity collapse" was falsified by `compound: true` — a field only `merge-concerns.sh` writes — proving the file postdated the collapse and was produced by the triage itself. Fixed at source on this branch by [43c75292](https://github.com/qmu/workaholic/commit/43c75292); the two archived files remain as historical evidence and are not back-filled.

## How to Fix

Add a `re-grade` mutator that rewrites `severity` in place and appends the rationale, so a re-grade is a scripted, staged change like every other concern mutation.

