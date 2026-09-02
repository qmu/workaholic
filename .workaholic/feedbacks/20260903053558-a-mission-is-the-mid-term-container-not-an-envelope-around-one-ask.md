---
type: Feedback
title: A mission is the mid-term container, not an envelope around one ask
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T05:35:58+09:00
author: a@qmu.jp
supersedes: 
---

# A mission is the mid-term container, not an envelope around one ask

Source: https://github.com/qmu/workaholic/issues/919

The operator restated what a mission is meant to be, and the corpus a loop-running repository
has accumulated does not match it.

## The grain, in the operator own words

> 1. ミッションは 2 枚以上のチケットを有するものであるべき。1 枚のチケットしかないのにミッションを作ることは当然できない。
> 2. たった 2 枚や 3 枚だけのチケットのミッションがたくさんできるというのも望ましくない。
>
> もう少しストラテジーとチケットの中間のところで、中期的なチケット計画やタスクアロケーションを行うことのできる器のある、そういった粒感がミッションになるはずであると考えている。

A mission is the mid-term container between a strategy and a ticket - the artifact with room in
it to plan tickets across a period and allocate them. It is not a wrapper around a request.

## Measured

94 missions on disk in one repository running this loop. One carries a single ticket, which
rule 1 says cannot be made. Eleven carry two or three tickets and twenty carry four or fewer,
so 21% of the corpus is the shape rule 2 calls undesirable. 52% sit at exactly seven or eight,
which is the "roughly 7-8 tickets, the ruled scale" wording printed straight into the
distribution.

Two mechanisms produce it, and neither is about capacity. /specificate emits one mission per
inbound ask - measured in a single hour, eight asks arrived from the channel, seven became
missions and one a record: seven missions inside twenty-one minutes, forty-eight tickets
between them. And the scale is a size rule rather than a capacity rule, so a small ask is
inflated to seven tickets while a genuinely mid-term programme gets no more room than a
one-line chat message.

Asked for: a mission is emitted because there is a mid-term plan to hold - several tickets
wanting ordering and allocation across a period - and never because an ask arrived. Concretely
a floor that survives the proposal so a mission below two tickets cannot exist; a stated
position on rule 2 so many two- and three-ticket missions is a defect the loop refuses rather
than a size it may choose; and the scale expressed as what the container must be able to hold
rather than as a ticket count to hit. An ask too small for that container has somewhere to go
already - a loose ticket, or the record alone.
