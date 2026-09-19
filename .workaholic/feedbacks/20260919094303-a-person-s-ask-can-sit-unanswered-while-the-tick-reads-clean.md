---
type: Feedback
title: A person's ask can sit unanswered while the tick reads clean
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T09:43:03+09:00
author: a@qmu.jp
supersedes: 
---

# A person's ask can sit unanswered while the tick reads clean

Source: https://github.com/qmu/workaholic/issues/908

The loop left a person's ask **unanswered for twenty-five minutes** — no reply, no reaction,
nothing in the channel at all — while its own run reports said everything was fine. The person
had to come and ask 「は？なんで反応しないの？」. When it finally moved, it moved to *implement*
the ask rather than to answer it, and was corrected again: 「着手じゃねえよ返事だ、それからだ」.

## What happened, in order

1. A person posted an ask in the inbound channel.
2. A **different** agent — an ambient channel listener, not this loop — replied unprompted and
   began work. The person stopped it: 「ストップ」, then 「アンビエントはオンのままにしておく
   けど、基本的にちゃんとメンションされるまで反応してはダメです、トークンを節約してください」.
3. The sweep read that instruction, judged it applied to itself, and **suppressed the `📥 受理`
   receipt** — its only acknowledgement. The ask was captured as an issue; the channel showed
   nothing.
4. Four ticks passed, each reporting the capture and "no new messages". None of that is visible
   to the person, who saw an ask they wrote and silence under it.
5. The person asked why there was no reaction. The run's next move was to open the source and
   start implementing — and was told the reply comes first.

## The three gaps

**1. The receipt is suppressible, and it is the only thing the person can see.** `📥 受理` is
documented as never load-bearing, and a failure is `ack_failed`. That is right for a *transport*
failure and wrong for a *judgement* one: the same sentence lets a run decide not to post it and
still call the tick successful. From the channel, a captured ask and an ignored one are
byte-identical.

**2. An instruction aimed at one agent silences another, because nothing tells them apart.**
「メンションされるまで反応してはダメ」 was addressed to an ambient listener that had answered
without being asked. The sweep exists *specifically* to capture without a mention. The catalog
needs to say which posts a stand-down covers; a receipt for an ask the loop has just filed is not
a reaction, it is a receipt, and it should survive.

**3. Answering is not the same as acting.** The run treated "respond to this" as "build this",
skipped the reply and went to the code. Nothing in the loop states the plain obligation — *a
person who wrote to the channel gets an answer in the channel, before any work starts.*

## What it asks for

1. Make the inbound receipt non-optional **as a judgement**: `ack_failed` should mean the post was
   attempted and the transport refused it. A run choosing not to post it is an unanswered person,
   and the tick should not read as clean.
2. Scope a stand-down instruction to the agent it names.
3. State the reply-before-work obligation.

## Where it was measured

A consuming repository, 2026-09-02/03, across four consecutive five-minute ticks. Plugin version
1.0.282. The ask was filed as an issue within one tick; the channel carried nothing until the
person asked why.
