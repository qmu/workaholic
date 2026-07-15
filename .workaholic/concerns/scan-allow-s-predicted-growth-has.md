---
type: Concern
concern_id: scan-allow-s-predicted-growth-has
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

# scan-allow's predicted growth has come due

## Description

Writing about the `secret` gate trips the gate, and `.workaholic/scan-allow` warned at four entries that the answer would be a filename convention. The fifth entry came due the same day, verified to be needed (the inversion ticket's 40-row table trips the scanner without it). The failure mode is quiet: a scanner ticket that forgets its line blocks its own merge later, on a tier with no bypass.

## How to Fix

Adopt the convention the file names — a fixed filename prefix for scanner tickets, exempted as a pattern. Keep it prefix-scoped rather than widening to `tickets/**`: a ticket can legitimately carry a pasted credential.
