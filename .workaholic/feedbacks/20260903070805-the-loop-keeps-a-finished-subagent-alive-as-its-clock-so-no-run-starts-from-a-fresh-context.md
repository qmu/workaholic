---
type: Feedback
title: The loop keeps a finished subagent alive as its clock, so no run starts from a fresh context
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T07:08:05+09:00
author: a@qmu.jp
supersedes: 
---

# The loop keeps a finished subagent alive as its clock, so no run starts from a fresh context

Source: https://github.com/qmu/workaholic/issues/928

The operator's intent for the loop is that a subagent is discarded when its work finishes, so
every run starts on a fresh context window. `commands/infinite-development.md` specifies the
opposite, deliberately, and the residency it produces is measurable.

## The ask, verbatim

> サブエージェントは処理が終わったらもう捨てる（毎回コンテキストウィンドウをフレッシュな状態で
> スタートさせるため）、そういう想定でいたのですが、今見ている限り team agents の機能を使って
> サブエージェントを常駐させているように見えます。

## What the command says

The agent listing is the loop's only state, and a finished subagent stays listed as **idle**
carrying the age it started at. An idle one is also the loop's own clock, which is why it is
**reaped at the spawn and not at the finish** — so a finished run is kept alive on purpose,
from its finish until whichever later tick happens to find it due.

## An idle agent is not a corpse

It is a resumable session holding its whole transcript: a send resumes it from that transcript.
Measured twice in one session — a correction sent to a finished `propose` and a truncated-report
request sent to a finished `moderate` both woke carrying their full prior context and continued
inside it. "Reaped at the next spawn" tidies the listing without giving back the context window.

## The running case is worse, and nothing bounds it

The concurrency rule is *a loop whose subagent is still running is not spawned again*, and
`/implement` takes unit after unit inside one run. Measured: one `implement` agent lived one hour
and thirty minutes — it landed a complete mission of eight tickets, then claimed and began a
second, unrelated mission, planning and implementing it inside a context that still carried the
whole of the first. Nothing in the loop bounds a run to one unit.

## The clock is the reason, and it is the cheap part to replace

The command states the cost of deriving the cadence from `started`: the age is measured from the
start of the previous run rather than its finish. Measured on the fifteen-minute `propose`
cadence in one session: respawned at ages of 21, 31 and 45 minutes — never near fifteen.

## What would make it done

- A subagent is stopped when its run finishes, not when the next one is due. Its result has
  already arrived as a task notification by then, so stopping it discards nothing.
- The clock stops being a live agent. A finish time is one line somewhere the tick already
  writes; `/moderate` keeps a tick log for exactly this class of question.
- A run is bounded to one unit. `/implement` claiming a second, unrelated mission inside one
  context is precisely the case the fresh-context intention exists to prevent.
