---
type: Feedback
title: The loop has clerks but no planner: nothing re-plans from the live board and convergence has no owner
kind: instruction
source: development
subject: person:the operator of a consuming repository
created_at: 2026-09-01T12:33:18+00:00
author: a@qmu.jp
supersedes: 
---

# The loop has clerks but no planner: nothing re-plans from the live board and convergence has no owner

kind: instruction / source: development / subject: person:the operator of a consuming repository

Source: https://github.com/qmu/workaholic/issues/845

# The loop has clerks but no planner — nothing re-plans from the live board, and convergence has no owner

Measured on a consuming repository, 2026-09-01, plugin 1.0.266, at the end of a day spent
unblocking the loop by hand. The operator's expectation, in their own words (translated):
"every hour, workaholic should keep fine-tuning the plan from the current state of the
strategies, missions and tickets, so that development repeats divergence and convergence in an
orderly sequence and builds its foundations autonomously." Their verdict on the day was deep
disappointment. The mechanism-level defects behind that day are filed separately (#830 #831
#836 #843); this record is the direction-level answer to why the day went the way it did.

## What the loop actually is: three clerks and no planner

`/specificate` is intake — it turns asks into missions and tickets. `/implement` is execution —
it claims and drives them. `/moderate` is bookkeeping — it reports anomalies and files them into
queues. Each is careful; none holds a plan. `/propose` is the closest thing: it reads the live
directions and plans the next mission — but it only ever ADDS. `/mission` can replan one in
flight, but a person must invoke it. moderate's `strategy-pace` and `direction-health` steps
read the plan's state and only report it. So no component autonomously reads the whole board —
which directions are dated when, which missions serve them, what the queue holds, what just
landed — and decides what happens NEXT, in what order, and what should STOP.

## One day's measured consequences

- **Six missions ran in parallel on one repository with no sequencing.** Every merge to the
  base re-conflicted every open pull request on the loop's own generated index, so five pull
  requests sat CONFLICTING while the tick reported them hourly as an external fact. Two
  missions in flight and four queued would have produced the same work with none of the
  conflicts. Nothing in the loop can make that call, because nothing owns the order.
- **Divergence has two owners; convergence has none.** Nothing closes, merges, re-orders or
  prunes. Missions at full acceptance stayed active with leftover tickets. The queue reached 30
  tickets against three directions all dated the same day, six days out, and nothing ever did
  the arithmetic; the dates moved only when a proposal a person triggered revised them. The
  loop cannot re-date its own plan from evidence.
- **The plan is not even readable, let alone adjusted** (#831): a mission carries no strategy
  field, so "what serves what, how far along, how much remains" is answerable only by a person
  with ad-hoc git commands over the bundle.
- **The loop's paperwork competes with the product.** Of 32 merges to the base in the day, 12
  were the loop's own proposals and records and 4 were repairs to its own plumbing; 16 changed
  the product.
- **The operator, not the loop, converged the day**: resolved five conflicting pull requests
  and merged nine, retired two dead claims, rescued unlanded work off an abandoned branch, and
  corrected the committed permission list the routines run under. Every one of those was
  visible to the tick and actionable by nothing in it.

## What is asked: give the loop a planning tick with authority, distinct from moderation's reporting

1. Each hour, or on each merge to the base, read the whole board — directions with dates,
   missions with acceptance, the queue, and what landed since the last reading — and ADJUST:
   order the queue, sequence the missions under an explicit work-in-progress limit, close what
   has converged, and re-date or escalate what the arithmetic says cannot land, BEFORE the date
   arrives rather than when it has passed.
2. Make convergence a first-class act with an owner. The planner may close a mission, merge
   two, retire a ticket that landed work has mooted, and hold new divergence while
   work-in-progress sits above the limit. Today every one of those waits for a human to notice.
3. Make the plan the artifact the hourly post reports: what landed, what that changed in the
   plan, what is next in order, and what needs a person — the delta of a plan, not an anomaly
   list. #831 asks for the reading; this asks for the adjusting that makes the reading worth
   posting.
4. Keep the loop's own paperwork out of the product's lane: batch the proposal and record
   commits, or move them off the base the way the tick log was moved, so a day of history reads
   as the product's day.

The expectation this answers is not exotic. It is what a competent human lead does with a board
every morning, and the loop runs hourly precisely so it could do it better than a morning. On
the measured day it did not do it at all.
