---
type: Concern
concern_id: validate-ticket-sh-never-validates-the
mission: []
tickets: [20260715121047-confine-writes-to-current-repo.md, 20260715121048-request-command-cross-repo-tickets.md, 20260715121049-remove-dead-leak-rule.md, 20260715121050-secret-pattern-misses-suffixed-keywords.md, 20260715132431-secret-scan-flags-type-annotations.md, 20260715143954-mission-relation-many-valued.md, 20260715163311-mission-lens-says-less.md, 20260715181934-invert-secret-pass2-to-match-values.md]
origin_pr: 86
origin_pr_url: https://github.com/qmu/workaholic/pull/86
origin_branch: work-20260715-112717
origin_commit: 12320d10
created_at: 2026-07-15T20:55:56+09:00
first_seen: 2026-07-15T20:55:56+09:00
last_seen: 2026-07-15T20:55:56+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# validate-ticket.sh never validates the mission relation

## Description

`validate-ticket.sh` has zero `mission` references, so both a typo'd slug and a bare `mission:` pass. The relation now carries more weight: `/drive` reads every named mission's quality gate, so a mistyped slug silently drops a gate rather than erroring ([83b88ff6](https://github.com/qmu/workaholic/commit/83b88ff6)).

## How to Fix

Resolve each slug against `.workaholic/missions/active/<slug>/mission.md` and fail on an unresolvable one.
