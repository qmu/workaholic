---
type: Feedback
title: The loop can stall at claimable 0 with no alarm
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-06T11:06:31+09:00
author: a@qmu.jp
supersedes: 
---

# The loop can stall at claimable 0 with no alarm

Source: https://github.com/qmu/workaholic/issues/1003

Measured on a consuming project over three days. Every active mission was held by a claim
whose branch had an open pull request, so `plan-units.sh` excluded all of them
(`claimed_resumable` x3, `claimed_undelivered` x1, `claimed_awaiting_verification` x1) and
`claimable-units.sh` answered `{"claimable":0,"missions":0,"backlog_units":0,"resumable":0}`.
The tick's allocation is `min(bound, claimable, what the machine can carry)`, so every tick
reported `watching`, spawned nothing and looked healthy. Twenty-eight queued tickets and four
open pull requests sat untouched for three days.

Two things make it a trap rather than a slow patch.

`claimable: 0` is reported the same way as *the queue is empty*. It is a real zero with
`readable` absent, so nothing distinguishes *there is no work* from *all the work is
unreachable*. The standing rule that a degraded read is never rendered as a healthy answer
does not apply, because from the reader's point of view the read is accurate and useless. The
survey already carries `excluded[]` with a reason per unit, so the tick could say
`all_claimable_excluded: <n> unit(s)` and name the reasons instead of a bare `watching`.

The state those claims were stuck in could not be exited by the loop at all. The remote
reported all four heads `CONFLICTING` while `git merge-tree --write-tree` merged three of them
cleanly. The project declares `merge=union` for its generated indexes and the remote's
mergeability computation does not apply merge drivers from `.gitattributes`, so every branch
after the first that touches a generated index is permanently `CONFLICTING` there, the merge is
refused, the claim is never delivered and the mission is never released. `/moderate`, the tick
that exists to find what has gone stale or stuck, reported nothing across three days.

The three things asked for:

1. The tick's report distinguishes an empty queue from a fully-excluded one, from the
   `excluded[]` the survey already returns.
2. `/moderate` treats `claimable == 0` with a non-empty `excluded[]` as a stuck condition worth
   naming to a human, with the exclusion reasons beside it.
3. The merge step prefers the local `git merge-tree --write-tree` verdict over the remote
   `mergeable` field when the project declares custom merge drivers.

Note beside the record: this repository already carries the `backlog_all_excluded` reading on
`plan-units.sh` for the ticket grain, which is the same shape asked for here one grain up, at
the unit level the tick's allocation actually reads.

This record is knowledge, not an ask the loop may act on: its `subject:` names an observer AI,
not a person, and its subject matter is the loop's own apparatus, so `/specificate` refused it
`self_authored` under `rules/workaholic.md`, *What May Originate a Mission*. The operator rules
on it.
