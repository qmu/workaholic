---
type: Feedback
title: blocked-tick picks its subject from every tick id in the day file and reports ok while blind
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-06T12:48:03+09:00
author: a@qmu.jp
supersedes: 
---

# blocked-tick picks its subject from every tick id in the day file and reports ok while blind

Source: https://github.com/qmu/workaholic/issues/1018

`/moderate`'s `blocked-tick` step exists to notice a tick that opened and never closed. On a
repository where the development loop is running it currently cannot notice one, and reports
`ok` while it fails to.

**Measured and reproduced 2026-09-06** by the session that filed the ask.

The subject is chosen lexically over **every** entry in the day file, whichever step wrote it:

    [.entries[].tick] | unique | reverse | map(select(. != $now)) | .[1] // ""

The day file has two kinds of writer. `tick-id.sh` mints `date -u`, so a moderate tick's own
sections are stamped `0…` for any morning hour UTC. The development loop's tick writes
`loop-finish-<name>` lines through the same `log-append.sh` with an id its caller supplies, and
a caller stamping local time on a UTC+9 machine produces `1…` for the same moment. `1…` sorts
above `0…`, so those entries own the top of the reversed list for the whole day and the subject
is always one of them.

The caller's clock is half of it and was corrected in the same change that filed this ask
(`date +%Y%m%d-%H%M%S` → `date -u`). The ask's position is that the step must not depend on
every caller agreeing about a clock, because the consequence of a disagreement is silence
rather than an error.

The other half is the step itself. A `loop-finish-*` section carries no `open`, so `opened=0` —
and `opened=0` takes the healthy branch, which prints the fixed sentence *"the tick before last
opened and closed; N step(s) recorded"* about a section that did neither.

Two repairs are asked for:

1. Choose the subject from sections that actually carry an `open`, rather than from every tick
   id in the file, so no other writer's id shape can capture it whatever clock it used.
2. Make `opened=0` its own reported state rather than folding it into health. *This section
   never opened* and *this section opened and closed* are different facts, and only one of them
   means the thing the step checks for is fine.

The propose arm is reported to have the same shape of hole from the other direction: it looks
for `propose-open` sections, while a consuming repository's propose runs record
`loop-finish-propose` and no `propose-open` at all, so that arm has had zero data since
2026-09-02 and reports nothing rather than reporting that it read nothing.

The net effect named by the ask is the one failure the step is for: a stopped moderate or
propose tick would go unseen while the log read healthy — the shape this loop refuses
everywhere else, a degraded read rendered as a healthy one.
