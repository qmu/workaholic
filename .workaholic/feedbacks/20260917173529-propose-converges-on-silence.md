---
type: Feedback
title: /propose converges on silence
kind: concern
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-09-17T17:35:29+09:00
author: a@qmu.jp
supersedes: 
---

# /propose converges on silence

kind: concern / source: development / subject: observer_ai:[Propose] routine

`/propose` produced **zero proposals on 64 consecutive ticks** over roughly four hours on a
consuming repository, while that repository's inbox held eight open items and `/implement` had
nothing queued at all. The operator's ruling on reading the run reports:

> propose は常にやることを見つけて改善し続けるために存在しており、implement の動機付けを
> 常に提供し続けるために存在します。「状態に変化なし」と言って止まることは許されません。

A routine whose whole purpose is to originate work is not allowed to converge on silence. It did,
it did so *correctly* by its own rules, and that is the defect.

## What was measured

The loop ran every five minutes. Every tick after the fourth was identical:

- `survey-strategies.sh` — `ok: true`, five active directions, no degradation.
- **Four refused `open_proposal`** — each because the proposal `/propose` itself had opened was
  still sitting in the inbox.
- **One eligible**, reading `quiescent: true`, judged `no_evolutionary_move` by the run.
- Result: `{"proposed": 0}`, tick after tick, reported as "no change".

Meanwhile: eight open inbound issues, zero open pull requests, zero queued tickets, and `main`
untouched for three and a half hours. The routine that exists to feed the loop was the quietest
part of it.

## Why the design produces this, and it is three things compounding

**1. `open_proposal` becomes a global stop when the next stage is not running.** The gate is
written as an in-flight brake — one mission per direction at a time — and it holds from the
moment the issue opens until `/specificate` merges its pull request. That is correct when
`/specificate` runs. When it does not, every direction `/propose` has ever proposed against
locks *permanently*, and the routine gates itself into silence one direction at a time. Nothing
in the survey can tell "work is progressing" from "the next stage is dead"; both read
`open_proposal`.

**2. `no_evolutionary_move` has no floor under it.** Since `over_cap` was retired there is no
bound in either direction: a tick may emit many proposals, or none, forever. The refusal is
documented as "a real answer, not a failure", and it is — for one tick. Sixty-four of them is a
routine that has stopped, and nothing in the design distinguishes the two.

**3. A move is declared against a strategy, so an ask with no direction can never be
originated.** In the measured case the operator's own stated immediate priority belonged to no
active strategy, so `/propose` was *structurally incapable* of proposing it — and spent two days
proposing against the directions that did exist, which is precisely what the operator had asked
it not to prioritise. `unattributed` exists on the inbound path and has no counterpart here.

## What this asks for

**A floor, not another gate.** `/propose` should be unable to end a tick having produced nothing
while there is anything it could name. Concretely, the run's own recommendation, in order:

1. **A zero-proposal tick is a finding, not an outcome.** When every direction is gated, the
   gating itself is the thing to report as work — `open_proposal` on four directions with an
   inbox that is not draining is a stalled downstream stage, and the routine should emit that
   rather than a silent line in a report nobody reads.
2. **`open_proposal` should not hold indefinitely.** A proposal that has sat un-ingested past
   some plain measure of the loop's own turn is evidence the next stage is not running; holding
   the origination gate on it makes one dead routine silence two.
3. **Give origination a path for an ask that answers no direction.** The inbound sweep already
   files `unattributed`; the strategy half has nothing equivalent, so the operator's priority
   can be captured and still never be worked on.

None of this asks for the judgement to be weakened — `describing_move`, `invented_obligation`
and the housekeeping refusal are the reason the output is worth reading. What is missing is that
the routine currently has an honest way to do nothing at all, and takes it.

## Where it was measured

A consuming repository, 2026-09-02, ticks 4 through 64 of a five-minute local `/loop`. Plugin
version 1.0.282. The run reports are in the session; the survey output was identical on every
tick from the fourth onward.


Source: https://github.com/qmu/workaholic/issues/907
