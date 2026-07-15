---
type: Concern
concern_id: missions-are-born-matching-the-lens
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

# Missions are born matching the lens's silence gate

## Description

The `0/0` filter ([87466e59](https://github.com/qmu/workaholic/commit/87466e59)) treats a symptom whose cause is upstream: `create.sh` scaffolds `## Acceptance` empty, so every mission is born matching the gate while carrying no signal, and can stay unfilled indefinitely. Accepted knowingly and recorded in `mission/SKILL.md`; `/mission summary` and `/catch` keep the lower assignee-only bar.

## How to Fix

If unfilled missions accumulate, fix `create.sh` — require a first acceptance criterion at creation — not more lens rules.
