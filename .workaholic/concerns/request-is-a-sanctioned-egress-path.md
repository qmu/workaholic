---
type: Concern
concern_id: request-is-a-sanctioned-egress-path
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

# /request is a sanctioned egress path from private context toward public repos

## Description

`/request` ([a15e7db8](https://github.com/qmu/workaholic/commit/a15e7db8)) carries content from private context toward potentially public repositories — the exact hazard the originating incident was made of. It is justified only by being narrow, explicit, and confirmed. The measured position is deliberate and stark: all four real leaked sentences file through `file-request.sh` **without complaint**, because none names this repo. The script's checks are mechanics, not assurance.

## How to Fix

Keep the verbatim-body confirmation non-skippable and treat any erosion as a design regression. The test asserting the four real leaks pass is a green-to-red tripwire: if it flips, the confirmation has been quietly demoted.
