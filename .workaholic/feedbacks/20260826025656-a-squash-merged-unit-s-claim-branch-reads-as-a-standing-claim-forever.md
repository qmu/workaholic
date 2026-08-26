---
type: Feedback
title: A squash-merged unit's claim branch reads as a standing claim forever
kind: insight
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T02:56:56+00:00
author: a@qmu.jp
supersedes: 
---

# A squash-merged unit's claim branch reads as a standing claim forever

The claim oracle (`drive/scripts/list-claims.sh`) reads **unmerged remote `work-*` branches**, and
a squash merge never makes the branch an ancestor of `main`. So a unit whose pull request landed by
squash keeps its claim standing forever, and `/moderate`'s `stalled-units` step reports it as stale
every hour with no way for the loop to ever clear it.

Measured on this repository, tick `20260826-025113` — three of the five "stalled" units had already
shipped:

- `make-the-draft-release-note-an-agent-s-release-plan` (`work-20260818-205051`) — PR #521 merged as
  the squash commit `159e15b0`; branch 11 commits off `main`, claim standing 117h.
- `make-workaholify-converge-the-account-s-routines` (`work-20260819-113836`) — PR #537 merged as
  `2d53cf1d`; branch 10 commits off `main`, claim standing 117h.
- `make-a-rename-a-registry-entry-not-a-sweep` (`work-20260821-035855`) — PR #546 merged as
  `4d331fd6`; branch 11 commits off `main`, claim standing 117h.

`workaholic:drive` states that **a merge releases a claim by definition**. That holds for a merge
commit and does not hold for a squash, and nothing in the protocol notices the difference. The cost
compounds: every such unit permanently occupies a slot in `stalled-units`' candidate set, so the one
surface that can reach a person about a genuinely stuck unit fills up with units that finished days
ago — and the tick's own five-question ceiling is spent on them.

What it needs is a ruling on where the release is proven. Reading the merge's own commit for the
`(#<N>)` squash marker, asking GitHub whether the head branch's pull request is `merged`, or having
`/ship` delete the head branch at merge time are all candidates; the oracle staying purely offline
(it degrades to `origin_unreachable` today, never to a GitHub read) is the constraint any of them
has to answer.
