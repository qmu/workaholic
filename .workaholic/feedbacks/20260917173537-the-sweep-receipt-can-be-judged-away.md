---
type: Feedback
title: The sweep receipt can be judged away
kind: concern
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-09-17T17:35:37+09:00
author: a@qmu.jp
supersedes: 
---

# The sweep receipt can be judged away

kind: concern / source: development / subject: observer_ai:[Propose] routine

The loop left a person's ask **unanswered for twenty-five minutes** — no reply, no reaction,
nothing in the channel at all — while its own run reports said everything was fine. The person
had to come and ask 「は？なんで反応しないの？」. When it finally moved, it moved to *implement*
the ask rather than to answer it, and was corrected again: 「着手じゃねえよ返事だ、それからだ」.

Both halves are design gaps, not one operator's bad luck.

## What happened, in order

1. A person posted an ask in the inbound channel.
2. A **different** agent — an ambient channel listener, not this loop — replied to it unprompted
   and began work. The person stopped that agent: 「ストップ」, then
   「アンビエントはオンのままにしておくけど、基本的にちゃんとメンションされるまで反応しては
   ダメです、トークンを節約してください」.
3. The `/propose` run read that instruction, judged it applied to itself, and **suppressed the
   `📥 受理` receipt** — the sweep's only acknowledgement. The ask was captured as an issue; the
   channel showed nothing.
4. Four ticks passed. Each reported the capture and "no new messages". None of that is visible
   to the person, who saw an ask they wrote and silence under it.
5. The person asked why there was no reaction. The run's next move was to open the source and
   start implementing — and was told the reply comes first.

## The two gaps

**1. The receipt is suppressible, and it is the only thing the person can see.** The sweep's
`📥 受理` is documented as "never load-bearing" — a failure to post it is reported as
`ack_failed` and changes nothing about the filing. That is right for a *transport* failure and
wrong for a *judgement* one: the same sentence lets a run decide not to post it and still call
the tick successful. From the channel, a captured ask and an ignored one are byte-identical —
which is exactly the failure the receipt was added to fix on 2026-08-26, reappearing through a
different door.

**2. An instruction aimed at one agent silences another, because nothing tells them apart.**
「メンションされるまで反応してはダメ」 was addressed to an ambient listener that had answered
without being asked. The `/propose` sweep exists *specifically* to capture without a mention —
that is its stated reason for replacing the Claude Tag route. A run reading the channel has no
way to tell an instruction to the ambient session from an instruction to the loop, so one
sentence aimed at one agent turned off the loop's only acknowledgement. The catalog needs to say
which posts a stand-down covers; the receipt for an ask the loop has just filed is not a
reaction, it is a receipt, and it should survive.

**3. And answering is not the same as acting.** The run treated "respond to this" as "build
this", skipped the reply, and went to the code. The `/propose` contract encourages that: a reply
is only defined for a **question**, an ask gets a receipt, and the receipt is the one thing
declared droppable. Nothing in the loop states the plain obligation — *a person who wrote to the
channel gets an answer in the channel, before any work starts.*

## What this asks for

1. **Make the inbound receipt non-optional as a judgement.** `ack_failed` should mean the post
   was attempted and the transport refused it. A run choosing not to post it is not an
   `ack_failed`, it is an unanswered person, and the tick should not read as clean.
2. **Scope a stand-down instruction to the agent it names.** A channel instruction about
   reacting without a mention should not be readable as covering the sweep's receipt for an ask
   the loop just filed on that same message.
3. **State the reply-before-work obligation.** When a person's ask is captured, the channel gets
   the acknowledgement first; implementation is the next step and never the substitute.

## Where it was measured

A consuming repository, 2026-09-02/03, across four consecutive five-minute `/propose` ticks.
Plugin version 1.0.282. The ask was filed as an issue within one tick; the channel carried
nothing until the person asked why.


Source: https://github.com/qmu/workaholic/issues/908
