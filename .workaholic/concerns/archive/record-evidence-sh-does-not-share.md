---
type: Concern
concern_id: record-evidence-sh-does-not-share
mission: []
tickets: [20260715121047-confine-writes-to-current-repo.md, 20260715121048-request-command-cross-repo-tickets.md, 20260715121049-remove-dead-leak-rule.md, 20260715121050-secret-pattern-misses-suffixed-keywords.md, 20260715132431-secret-scan-flags-type-annotations.md, 20260715143954-mission-relation-many-valued.md, 20260715163311-mission-lens-says-less.md, 20260715181934-invert-secret-pass2-to-match-values.md]
origin_pr: 86
origin_pr_url: https://github.com/qmu/workaholic/pull/86
origin_branch: work-20260715-112717
origin_commit: 12320d10
created_at: 2026-07-15T20:55:56+09:00
first_seen: 2026-07-15T20:55:56+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163005-release-scan-and-ship-gaps.md (2026-07-16 triage-to-zero): share the _SP_KEY group and pass 1 between the branch scanner and the evidence guard. Risk now tracked in the queue.
closed_at: 2026-07-16T17:10:09+09:00
---

# record-evidence.sh does not share secret-patterns.sh, contrary to three documents

## Description

`ship/record-evidence.sh` keeps an inline copy of the credential regexes rather than sourcing `release-scan/scripts/lib/secret-patterns.sh` — despite that file's header, the inverting ticket's step 5, and CLAUDE.md all asserting a sharing relationship that never existed. Measured drift: the evidence guard misses all five suffixed-keyword shapes the scanner has caught since [84d238d9](https://github.com/qmu/workaholic/commit/84d238d9), and refuses 17 of the 25 reference shapes the scanner now subtracts (see [e3366bfd](https://github.com/qmu/workaholic/commit/e3366bfd) in `plugins/workaholic/skills/ship/scripts/record-evidence.sh`). All three documents are now corrected.

## How to Fix

Share the **key group and pass 1 only** — do not unify. The two guards read different material and want opposite bars: the scanner reads code, where a reference is ordinary and a false positive hard-blocks `/ship`; `record-evidence.sh` reads free-text deploy evidence entering a public story, where a false positive costs a rephrase and a false negative publishes a credential. Pass 2's value judgment is code-shaped and would weaken it.

