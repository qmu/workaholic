---
type: Concern
concern_id: the-key-bareword-ambiguity-is-irreducible
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

# The `key: bareword` ambiguity is irreducible and its resolution has already flipped twice

## Description

`apiKey: string` and `password: mysecret123` are the same shape and the line carries nothing separating them; matching on the value does not help, since both values are bare words, and `grep -Ei` closes off the uppercase heuristic. Not theoretical: [c245361e](https://github.com/qmu/workaholic/commit/c245361e) resolved it toward "type" and silently stopped flagging three real credential shapes; [1fd4ef63](https://github.com/qmu/workaholic/commit/1fd4ef63) resolved it back. A bounded primitive list therefore survives the inversion, contrary to the origin ticket's claim — and it is load-bearing, since `readonly apiKey: string` is real TypeScript that would otherwise hard-block.

## How to Fix

Keep erring toward flagging and keep the reasoning in the file so the list is not "simplified" away. Two open questions are cheaper together: whether `_SP_KEY` needs a left word boundary (`htmlToken` matches `token` today), and whether a case-sensitive stage is worth splitting out.
