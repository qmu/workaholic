---
type: Feedback
title: Say what the direction could not see before calling it arrived
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T01:17:27+00:00
author: a@qmu.jp
supersedes: 
---

# Say what the direction could not see before calling it arrived

Source: https://github.com/qmu/workaholic/issues/670

The `[Propose]` routine opened this against the strategy
`an-autonomous-improvement-loop-run-by-the-routines`, declaring a `contraction` move.

## What was asked

Stop a completion reading from speaking past what the attribution walk could actually see.

Measured on this repository at 2026-08-28 00:41 UTC, on that strategy's own survey row:
`quiescent: true`, `waiting_missions: 0`, `waiting_count: 0`, `landed` 125 — the direction
reads **arrived**, three days before its `target_date`. At the same instant the tree holds
four active missions and ten queued tickets, and `strategy/scripts/mission-strategy.sh`
answers `attributed: false` for every one of the four:

- `make-workaholify-converge-the-account-s-routines` (1 queued ticket)
- `make-the-routine-create-body-documented-and-buildable` (3 queued tickets)
- `refuse-ok-under-a-placeholder-identity` (2 queued tickets)
- `deploy-the-docs-site-on-merge-to-main` (3 queued tickets)

The first three are that direction's own machinery. They are invisible to
`attributed-work.sh` because their `feedback:` refs do not intersect the strategy's, which is
the documented and accepted limit of a lossy one-way walk. What is not acceptable is that
three readings built on top of that walk — `waiting_missions`/`waiting_count` (the
`work_waiting` brake), `dormant`, and `quiescent` — each treat *could not attribute* as *does
not exist*, and then speak in the vocabulary of completeness. `quiescent` means "everything I
could attribute has landed" and is rendered to the operator as "this direction has arrived".

So in three days `/moderate` would ask that strategy's assignee `direction-arrived:<slug>` and
invite them to close a direction with ten of its own tickets queued behind three of its own
missions, and the question would name none of them.

## What must become true

1. The unattributed residue of the live tree — active missions and queued tickets that no
   strategy claims — is readable, by name, through one pure reader composing the walk that
   already exists (`mission-strategy.sh`), adding no field to any artifact and reviving no
   relation.
2. Every survey row carries that residue, eligible and refused alike, and no gate, no sort and
   no `selected` moves — the discipline `overdue`, `dormant` and `quiescent` each already
   follow.
3. `quiescent` is never `true` over a residue read that was degraded — the
   `unreadable`-is-never-`dormant` precedent, and `no_feedback_refs`'s rule that a gate that
   cannot be read is not a gate.
4. The arrival question and the run report name the residue — the missions by slug, not a
   count — so nobody is invited to close a direction over work they cannot see.
5. The repair is reachable through the loop: an operator who rules that an unattributed mission
   does answer a direction announces it, and the loop carries that ruling by appending the
   strategy's own existing `feedback:` refs to that mission, through a publish tree behind a
   pull request, adding no field and reviving no `strategy:` relation.

## What it was chosen against

**Widen the attribution walk** — teach `attributed-work.sh` to infer a direction from a
mission's subject, or revive the `strategy:` relation. Refused: the relation was removed on
2026-07-28 for giving ownership a second resolution path, and 2026-08-13, 2026-08-17 and
2026-08-26 each declined to bring it back; inference would put a machine's guess where the
operator's citation belongs.

**Narrow only the wording** — have the arrival question say "as far as I can see". Refused
because it costs the operator the same hand-read it costs today: they learn the answer is
partial and still cannot see what was missing.

## The plan the ask carried

Eight ordered tickets: reproduce the false arrival mechanically; `unattributed-work.sh` as a
pure reader; carry the residue onto every survey row; refuse an arrival over a degraded residue
read; name the residue in `/moderate`'s arrival question; name it as evidence in `/propose`'s
run report; carry an operator's attribution ruling through the loop as an append of the
strategy's own refs to a named mission; drill it with no network and update the documents in
the same change.
