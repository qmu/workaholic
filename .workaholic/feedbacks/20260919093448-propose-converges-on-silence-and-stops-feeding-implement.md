---
type: Feedback
title: Propose converges on silence and stops feeding implement
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T09:34:48+09:00
author: a@qmu.jp
supersedes: 
---

# Propose converges on silence and stops feeding implement

Source: https://github.com/qmu/workaholic/issues/907

`/propose` produced **zero proposals on 64 consecutive ticks** over roughly four hours on a
consuming repository, while that repository's inbox held eight open items and `/implement` had
nothing queued at all. The operator's ruling, in their own words:

> propose は常にやることを見つけて改善し続けるために存在しており、implement の動機付けを
> 常に提供し続けるために存在します。「状態に変化なし」と言って止まることは許されません。

A routine whose whole purpose is to originate work is not allowed to converge on silence. It did,
it did so *correctly* by its own rules, and that is the defect.

## What was measured

Every tick after the fourth was identical: `survey-strategies.sh` `ok: true`, five active
directions, no degradation; **four refused `open_proposal`**, each because the proposal
`/propose` itself had opened was still sitting in the inbox; **one eligible**, reading
`quiescent: true`, judged `no_evolutionary_move`. Result `{"proposed": 0}`, tick after tick,
reported as "no change" — beside eight open inbound issues, zero open pull requests, zero queued
tickets, and `main` untouched for three and a half hours.

## Why the design produces it — three things compounding

1. **`open_proposal` becomes a global stop when the next stage is not running.** The gate holds
   from the moment the issue opens until `/specificate` merges its pull request. That is correct
   while `/specificate` runs; when it does not, every direction the routine has ever proposed
   against locks permanently, and nothing in the survey can tell *work is progressing* from
   *the next stage is dead* — both read `open_proposal`.
2. **`no_evolutionary_move` has no floor under it.** Since `over_cap` was retired there is no
   bound in either direction. The refusal is a real answer for one tick; sixty-four of them is a
   routine that has stopped, and nothing in the design distinguishes the two.
3. **A move is declared against a strategy, so an ask that answers no direction can never be
   originated.** The operator's own stated immediate priority belonged to no active strategy, so
   `/propose` was structurally incapable of proposing it. `unattributed` exists on the inbound
   path and has no counterpart here.

## What it asks for

**A floor, not another gate.** `/propose` should be unable to end a tick having produced nothing
while there is anything it could name:

1. A zero-proposal tick is a **finding**, not an outcome — when every direction is gated, the
   gating itself is what to report as work.
2. `open_proposal` should not hold indefinitely: a proposal un-ingested past a plain measure of
   the loop's own turn is evidence the next stage is not running, and holding origination on it
   makes one dead routine silence two.
3. Origination needs a path for an ask that answers no direction.

None of this weakens the judgement — `describing_move`, `invented_obligation` and the housekeeping
refusal are the reason the output is worth reading. What is missing is that the routine currently
has an honest way to do nothing at all, and takes it.

## Where it was measured

A consuming repository, 2026-09-02, ticks 4 through 64 of a five-minute local `/loop`. Plugin
version 1.0.282.
