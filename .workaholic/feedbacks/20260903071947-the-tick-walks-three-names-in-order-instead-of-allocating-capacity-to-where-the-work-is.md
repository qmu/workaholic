---
type: Feedback
title: The tick walks three names in order instead of allocating capacity to where the work is
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T07:19:47+09:00
author: a@qmu.jp
supersedes: 
---

# The tick walks three names in order instead of allocating capacity to where the work is

Source: https://github.com/qmu/workaholic/issues/930

The tick's allocation is a constant. The loop's state is not. So the runner that is the
bottleneck never gets more capacity, and the runner that has nothing to do is walked anyway.

## The ask, verbatim

> 例えばこのループ中の状態に応じて、毎ティックの実行を変える（律儀に propose を舐めなくても、
> 今回の tick では implement を見守る、や、implement の sub agent を追加して並行して進められる
> ものを進める、といった最適な采配を振るってほしい）

> 消化に集中すべき時は可能な限りファンアウトして消化してほしいんですよ
> そういう柔軟対応を tick でしてほしい

## What the command specifies

Three fixed cadences — `implement` every tick, `propose` every 15 minutes, `moderate` every 30 —
and one gate per name. **One agent per name**, because the concurrency rule is *a loop whose
subagent is still running is not spawned again*. Nothing anywhere reads how much work is queued,
or where it is.

## Measured, in one session of roughly two hours

- 54 tickets in `todo`, across 8 active missions.
- One `implement` runner, by construction. It landed two units in that time — one mission of
  eight tickets and one of seven — and is on its third. At that rate the standing queue is about
  seven hours of strictly serial work.
- Every direction was refused on every survey: `work_waiting` with 7, 9 and 38 tickets waiting,
  or `not_active`, or `quiescent`.
- The strategy half of `propose` produced zero proposals on every run of the session, each time
  re-deriving a gate whose inputs could not have moved, because `work_waiting` only clears when
  `implement` drains the queue — the one thing the tick has no way to accelerate.

## Two structural facts behind it

1. One agent per name caps `implement` at one, whatever the queue holds. Eight active missions
   with no claim on them, 54 tickets, and a rule that permits exactly one runner. Adding capacity
   is not merely un-attempted; the concurrency rule forbids it.
2. `propose` bundles an event-driven half with a state-gated half behind one number. Ingest
   should run when an ask has been captured — and the tick is the thing that captured it; it
   filed the issue itself moments earlier, so no derivation, no detector and no second reader is
   involved. The strategy judgement is the half that genuinely wants a cadence.

## The standing objection, engaged rather than ignored

The command rejects state-dependence for `propose` by name: *a cadence is the honest bound and a
change-detector is not — has the queue moved is a second derivation of the gate `/propose`
already owns.* That argument is about the **strategy** half and it holds. It does not reach the
**ingest** half, where the event is the tick's own act rather than a state it would infer. And it
says nothing at all about how many `implement` runners there should be.

## What would make it done

The tick decides an allocation each time, from what it has just read. Its job is not to walk
three names in order; it is to put the session's capacity where the work is.

- When draining is the right thing, fan out as far as the work allows — several `implement`
  runners at once, one per independently claimable unit, up to a declared bound. The claim
  protocol already refuses what is taken, so the safety this rests on is in place.
- A runner whose answer cannot have changed is skipped, not walked.
- The ingest half runs the moment the tick's own sweep captured an ask.
- A tick may decide to do nothing but watch, as a decision rather than the residue of three
  gates all answering no.
