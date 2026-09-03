---
type: Feedback
title: The tick's fixed cost is paid every five minutes, and most of it answers nothing
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T07:14:48+09:00
author: a@qmu.jp
supersedes: 
---

# The tick's fixed cost is paid every five minutes, and most of it answers nothing

Source: https://github.com/qmu/workaholic/issues/929

The loop runs forever, so its **fixed** per-tick cost is the number that matters, and it is
larger than the work most ticks do. Measured over roughly two hours of one session — about
twenty-three ticks, four of which captured an ask, the majority reporting a quiet channel with
nothing reaped and nothing spawned.

## 1. `log-read.sh` returns the whole day to answer one timestamp

The tick's `moderate` gate needs exactly one value: how old the newest tick in the log is.
`log-read.sh` returns every entry of the day. Measured: the payload went from about 12 KB early
on to 50,087 bytes two hours later, read on every tick, twelve times an hour, growing
monotonically until the day rolls over. Nothing else in the tick consumes those entries. A
`--newest` mode — the newest tick's id and day, and nothing else — replaces 50 KB with one line
at no cost to any other reader.

## 2. The command body is the per-tick fixed cost, and most of it is not operative

`commands/infinite-development.md` is 1,775 words / 11,291 bytes, and the loop runs in one
session that never resets, so the body is re-paid every five minutes — on the order of twenty
thousand words an hour before any work happens. A large share is measurement and rejected
alternatives, load-bearing for a person deciding whether to change a rule and not for a run
applying it. The split already exists in this plugin: `workaholic:notify` keeps its rules in
`SKILL.md` and its measurements, shapes and history in `reference/notifications.md`. This is the
largest single lever, because it is paid on every tick whether or not anything happened.

## 3. A run's result reaches the parent twice

Measured once: a `/moderate` run delivered its report as a summary message and as an idle
notification carrying substantially the same content — a thirty-one step table, twice, into the
parent's context. The idle notification always arrives; the summary is the duplicate.

## 4. A quiet tick still reports at length

The command asks for a per-loop line every tick. The majority of this session's ticks had nothing
to say and still printed four to six lines of `still_running` / `not_due`. The principle is
already written elsewhere in this plugin — the moderator's post gate makes an idle hour silent —
and the tick's own terminal report does not follow it.

## 5. The channel read asks for more than the tick uses

The tick needs author, timestamp and text. The connector's default detailed format adds reactions
and thread metadata for every message, on every tick. Naming the concise format in the command is
free and changes no behaviour the tick depends on.

## What would make it done

Items 1, 3, 4 and 5 are small and independent. Item 2 is the one that decides whether an
always-on loop is affordable: the recurring cost of a tick should be the operative instructions,
not the record of how they were arrived at.
