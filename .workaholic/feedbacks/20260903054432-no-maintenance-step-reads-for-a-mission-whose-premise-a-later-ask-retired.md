---
type: Feedback
title: No maintenance step reads for a mission whose premise a later ask retired
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-03T05:44:32+09:00
author: a@qmu.jp
supersedes: 
---

# No maintenance step reads for a mission whose premise a later ask retired

Source: https://github.com/qmu/workaholic/issues/926

An observer AI reported that an operator's ask can retire the premise of missions already in
flight, and that no step of the maintenance tick reads for it.

## What the ask says

An ask arrived saying, of a set of screens: throw all of it away, integrate what exists into one
prototype, and link that from the top. It was captured, proposed and merged, and the new mission
opened — while four missions under the same direction were still active and still about fixing or
showing the very screens the ask discards. Six missions then ran in parallel under one direction,
four of them standing on a premise that had just been withdrawn.

## The gap it names

Three maintenance steps already read a mission's health — `closable-missions` (acceptance fully
ticked with tickets still queued), `retire-claims` (a claim proved superseded) and
`unrecorded-missions` (a pull request closed unmerged with nothing recorded). None of them reads a
mission's **premise** against the asks that arrived after it opened. A premise-retired mission is
byte-identical to an ordinary young one: nothing stalled, nothing raced, nothing undelivered, and
its acceptance unticked precisely because the work has not been done.

The ask places the repair in the tick rather than in `/specificate`, on the ground that
`/specificate` sees one ask at a time and decides mint-or-extend for that ask alone, while the tick
already reads every active mission and every recently captured ask — the only place holding both
halves. What it asks for is a step that names such a mission **for a person to rule on**, never one
that closes it.

## Why this is recorded and not proposed

The ask is machine-originated (`subject: observer_ai:`) and its subject is the loop's own
apparatus — a new step in the maintenance tick. `rules/workaholic.md`, *What May Originate a
Mission*, is explicit that such a record may not originate one: only a human's ask or a
human-authored strategy may. So this run captures the observation as knowledge and emits no
mission and no ticket. The finding stays open for a person to read and, if they want it built, to
ask for in their own words.
