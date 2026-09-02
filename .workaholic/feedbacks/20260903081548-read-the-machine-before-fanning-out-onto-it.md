---
type: Feedback
title: Read the machine before fanning out onto it
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T08:15:48+09:00
author: a@qmu.jp
supersedes: 
---

# Read the machine before fanning out onto it

Source: https://github.com/qmu/workaholic/issues/936

The tick decides how many runners to start and never reads the machine it is starting
them on.

## The ask, verbatim

> マシンのロードアベレージも見ながらファンアウトしないとダメだね

## What was measured, mid-fan-out

Three concurrent `implement` runners on a four-core machine:

```
loadavg   7.99  6.42  5.60      (1 min / 5 min / 15 min)
cores     4
memory    8128 MB used of 16218, 8090 available
thermal   64.2 °C, throttled=0x0
```

Load was roughly twice the core count, and the fifteen-minute figure says it had been over
capacity for a while — not a spike. Three agent processes sat at 79–91 % CPU each beside two
long-lived ones at 19.8 % and 17.6 %, with an `npm test` in the mix. Memory was half free and
the SoC was not throttling: CPU was the binding resource, and the other two are named here so
the reading is not over-claimed.

## Why the reporter calls it the tick's problem

The spawn decision reads `ListAgents` and three cadences. Nothing anywhere reads `nproc`, load,
memory or temperature, so the decision to add a runner is made from queue depth alone — and on
exactly the same evidence it used to add the third, it would add a fourth and a fifth. Past the
core count each added runner makes every other runner slower, throughput per runner falls,
wall-clock per unit rises, and the loop observes only that units are still landing. The failure
is quiet.

The machine is not incidental: the loop is meant to run forever on whatever machine its
developer has, and a small single-board computer and a large workstation currently receive the
same instruction.

## What the ask says would make it done

- The machine is an input to the spawn decision — core count and the one-minute load average
  are one call and one file, cheaper than reads the tick already makes every five minutes.
- A stated bound and a named refusal: when load per core exceeds a declared ratio, another
  runner is not started and the tick says so by name (`load_saturated: 7.99/4`), the way every
  other refusal in this loop is named rather than silent.
- The reading gates adding, never stopping. A running unit is never killed for load — that
  throws away work in progress, the same mistake a too-eager staleness threshold makes.
  Measured the same day: a unit that looked stalled for twenty minutes was reading documents
  and landed shortly after.
- CPU first, honestly scoped. Memory and thermal readings are worth carrying, but on the
  measurement above neither bound anything.

The reporter names this as the same seam as the tick's allocation being three constants rather
than a judgement: the machine is one of the inputs that judgement needs, and today it has none.
