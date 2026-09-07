---
type: Feedback
title: Read moderate's cadence from its own recorded finish
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-07T03:08:05+09:00
author: a@qmu.jp
supersedes: 20260906110057-the-tick-s-own-log-writes-suppress-the-moderate-spawn-forever.md
---

# Read moderate's cadence from its own recorded finish

Source: https://github.com/qmu/workaholic/issues/1055

Read `moderate`'s cadence from its own recorded finish, not from the tick log's bare newest
tick. `commands/infinite-development.md` §2 gives `moderate` a different gate from the other two
loops: `implement` and `propose` are read with `log-read.sh --step-prefix loop-finish-<name>
--latest-tick`, while `moderate` is read with `log-read.sh --latest-tick` and no step prefix. Both
read the same file, `.workaholic/moderations/<UTC-day>.md`, and the coordinator tick writes its own
`loop-finish-<name>` lines into that file under the **coordinator's** tick id every time it observes
a subagent idle — so the bare read answers whichever tick wrote last, which is normally the
coordinator.

Measured at coordinator tick `20260906-175547`: `log-read.sh --latest-tick` answered
`20260906-174615` while `log-read.sh --step-prefix loop-finish-moderate --latest-tick` answered
`20260906-173626`. The first is this session's own `loop-finish-propose` line; the real moderate
finish is 19 minutes older than the gate believes. Because the tick writes a `loop-finish-*` line on
most ticks, each such write moves the bare reading forward, so on a busy loop the gate can read
"moderate ran just now" indefinitely and never fire — stopping the maintenance tick silently, with
no degradation word for it, because the read succeeds and returns a real tick id. This tick did not
diverge in outcome (both readings are under 30 minutes), so it is reported before it bites rather
than after.

The shape asked for is the reader the other two loops already use —
`--step-prefix loop-finish-moderate --latest-tick` — so every cadence in the loop is keyed on that
loop's own recorded finish. Every existing rule is kept: an empty `latest_tick` is *no such tick* and
is due; an unreadable log is due; a recorded finish older than 30 minutes is due. The ceiling
(`commands/infinite-development.md` §2) and `skills/work/SKILL.md` are updated in the same change.
Non-goals: no second log, no cursor, no field on any artifact, and the tick keeps writing its
`loop-finish-*` lines into that file — they are correct where they are; only the reader is wrong.

This is the operator's ruling on the concern the loop filed about itself on 2026-09-06
(`20260906110057-the-tick-s-own-log-writes-suppress-the-moderate-spawn-forever.md`, refused
`self_authored` and left for the operator to rule on).
