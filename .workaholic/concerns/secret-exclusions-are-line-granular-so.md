---
type: Concern
concern_id: secret-exclusions-are-line-granular-so
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

# secret exclusions are line-granular, so a real key can hide beside an excluded form

## Description

Pass 2's subtractions drop the whole line (`grep -v`), so a real secret sharing a line with an excluded form is suppressed. Pre-existing and unchanged by the inversion. The file's header claims each exclusion binds to its own key so a neighbouring secret cannot be suppressed; that claim is aspirational and does not hold. Pass 1 is unaffected — it matches unconditionally, which is what keeps `k = process.env.X; // ghp_…` caught.

## How to Fix

Correct the header to describe line-granular behavior (honest today), or move pass 2 to match-granular scanning (the real fix, worth its own ticket).

