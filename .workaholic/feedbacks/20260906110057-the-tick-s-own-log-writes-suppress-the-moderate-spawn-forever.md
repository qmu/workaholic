---
type: Feedback
title: The tick's own log writes suppress the moderate spawn forever
kind: concern
source: development
subject: observer_ai:workaholic-loop
created_at: 2026-09-06T11:00:57+09:00
author: a@qmu.jp
supersedes: 
---

# The tick's own log writes suppress the moderate spawn forever

Source: https://github.com/qmu/workaholic/issues/1000

The `moderate` spawn gate in `commands/infinite-development.md` §2 reads the tick log's
newest section with no step filter (`log-read.sh --latest-tick`), while the same section
instructs the tick to write `loop-finish-<name>` lines into that log under the tick's own
id. A `loop-finish-implement` line written at tick T creates section `## T`, so the next
tick's unfiltered read answers T — the tick's own write, not a `/moderate` run. Since
`implement` runs every tick, an idle `implement` observed on any tick pushes the 30-minute
gate forward by 30 minutes, every five minutes, indefinitely.

Measured on this machine, 2026-09-06: `.workaholic/moderations/2026-09-06.md` ends with a
`loop-open` section written by the tick at `20260906-011209`, while the `moderate` run it
would stand for last finished at `00:49:24`. Read unfiltered at 01:16 the gate answers
"4 minutes old" and refuses the spawn; read against `moderate`'s own recorded finish it
answers "27 minutes". The two readings disagree by the whole width of the gate.

Why it matters: `moderate` is the only tick that notices absence — a stalled claim, a
stranded publication, a lapsed cadence, a red base, a blocked tick. Silencing it is
invisible by construction, because nothing reports a maintenance tick that was never
spawned. The repository already carries the general form of this rule (a degraded read is
never rendered as a healthy `not_due`); this is the same failure reached by a write rather
than a read.

The neighbouring cadences already read `log-read.sh --step-prefix loop-finish-<name>
--latest-tick`, which is the shape the `moderate` gate lacks.

This record is knowledge, not an ask the loop may act on: it was written by a loop session
about the loop's own apparatus, so `/specificate` refused it `self_authored` under
`rules/workaholic.md`, *What May Originate a Mission*. The operator rules on it.
