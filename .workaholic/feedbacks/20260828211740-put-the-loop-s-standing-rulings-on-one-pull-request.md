---
type: Feedback
title: Put the loop's standing rulings on one pull request
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T21:17:40+00:00
author: a@qmu.jp
supersedes: 
---

# Put the loop's standing rulings on one pull request

Source: https://github.com/qmu/workaholic/issues/691

The `[Propose]` routine asks that the loop gain one way to hand the operator a ruling
it cannot make itself — as a pull request carrying the machine's proposed answer and
the evidence behind it — instead of restating the same question every hour forever.

Two rulings are standing on this repository right now and neither is reachable by any
act the loop can take:

- **Which direction an unattributed mission answers.** `strategy/scripts/unattributed-work.sh`
  names four active missions and one loose queued ticket belonging to no direction.
  `strategy/scripts/carry-attribution.sh` is the writer that settles each one, and it
  fires only when the operator announces the pair by explicit slug through `/specificate`.
- **Which account an unmapped address belongs to.** `workaholify/scripts/audit-identity-coverage.sh`
  reports `identity_map_uncovered`; five tickets stamped an unmapped address have been
  undrivable by every runner since 2026-08-21. `apply-bootstrap.sh` writes the proposed
  mapping line as a comment a person must complete by hand on `main`.

What must become true: a tick composes those readings into one set of standing rulings,
the run judges each one and states its evidence, the judged ones are drafted into a
publish tree through the writers that already own them, and the whole set lands as one
pull request that never auto-merges — the operator's merge is the ruling, exactly as
their merge is the authorship of a strategy `/specificate` drafted. A ruling the run
cannot judge stays a question and is never written. Nothing is written to `main` by a
machine, no artifact gains a field, and no reading, question key or gate that exists
today moves.

The direction it commits to: the Aim says a person supplies the direction rather than
the ticket, and the origination half of that has arrived while the developer's work
became a standing queue of item-level rulings — four attributions to announce one slug
at a time, one mapping line to uncomment, and an hourly question restating each. The
operator should keep every decision and stop keeping the queue.

Chosen against: finishing the retirement CI cannot complete (the repair of a mechanism
that landed hours ago, which `/moderate`'s `retire-blocked:<unit>` question already
raises), closing the residue on the loop's own arithmetic (a run disposing of work
nobody ruled on is the opposite of moving the decision up a layer), and asking harder
(the questions are not failing to be asked, they are failing to be actionable in one
place).
