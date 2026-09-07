---
type: Feedback
title: The daily digest reports itself already posted on a day no root was posted
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T18:12:22+09:00
author: a@qmu.jp
supersedes: 
---

# The daily digest reports itself already posted on a day no root was posted

Source: https://github.com/qmu/workaholic/issues/1034

## What was measured

`.workaholic/moderations/2026-09-06.md`, read on 2026-09-06 at 09:02 UTC after nine
`/moderate` ticks:

- `human-checkin-post` lines in that day file: **0**. No Moderation root was posted at any
  point that day — every tick's `render-tick-post.sh` answered `post: false` / `off_day`
  (Sunday, outside `WORKAHOLIC_WORK_DAYS`), and no transport could have carried one anyway
  (the connector does not resolve `dev-workaholic`, `SLACK_BOT_TOKEN` is unset).
- `strategy-digest` nonetheless logged, on its first three ticks:

  ```
  - `strategy-digest`: ok — morning digest ready for 2026-09-06: 1 strategies, 10 commits
  ```

  and on every tick after that:

  ```
  - `strategy-digest`: ok — the 2026-09-06 digest is already in a Moderation root
  ```

The step asserts the digest is in a Moderation root on a day whose own log shows no root
was ever posted. The log contradicts the step's own summary.

## The shape of the gap

Whatever `strategy-digest` keys its once-a-day dedup on, it is not delivery, and it is not
the `human-checkin-post` line that records a delivery. Something a *rendering* wrote was
read back as evidence that a *post* happened.

The ask deliberately stops at what was measured rather than naming the mechanism: the two
log facts are certain, the derivation behind them is not, and guessing it would put a wrong
repair in the record.

## Why it matters

The speaking window opens on the next working day. If the marker persists — or if the same
false reading recurs on a day whose window *is* open — the day's first Moderation root can
carry no digest, because the step believes one already went out. That is the failure class
this repository keeps closing elsewhere: a reader rendering its own state as an outcome it
never observed.

The day gate itself is not in question. Holding a root on `off_day` is designed behaviour,
and so is holding every question with it. This is also distinct from #806 and #939, which
are about the transport being out; this claim would be false regardless of why nothing was
posted.

## What the ask does not ask for

No gate is proposed for removal and no repair is specified. Whether the dedup should key on
a delivery rather than on a render — and if so, on which line — is named as an engineering
judgement for the operator, not one the loop should make about its own apparatus.

## Judgement on this run

`ask-origin.sh` reads this ask **`machine`** (`subject: observer_ai:workaholic-loop`), and
its subject is the loop's own apparatus — `/moderate`'s `strategy-digest` step and the tick
log it reads. Both halves of the operator's rule hold, so this run is **record-only,
`self_authored`** (`rules/workaholic.md`, *What May Originate a Mission*): the record is
written and nothing is originated from it. The finding stays open as knowledge, and a
person may disagree with this judgement here.
