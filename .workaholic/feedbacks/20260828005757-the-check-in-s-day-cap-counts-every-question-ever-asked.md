---
type: Feedback
title: The check-in's day cap counts every question ever asked
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-28T00:57:57+00:00
author: a@qmu.jp
supersedes: 
---

# The check-in's day cap counts every question ever asked

The check-in's daily cap counts every question the tick has ever asked, not today's, so it can never ask again.

## What was measured

Tick 20260828-005129 held five questions it had never asked before -- a red base (`base-red:6f473ec`, `validate` failing on main), a declared verification handoff (PR #647), and three blocked claim retirements. Every one came back:

```
{"ask": false, "reason": "day_cap", "hold": true, "asked_today": 12, "max_per_day": 10}
```

The tick log holds twelve `human-checkin-ask-*` lines in total, spread over five separate days (2026-08-18, 08-19, 08-26, 08-27). Today's file, `.workaholic/moderations/2026-08-28.md`, holds none.

## Where it comes from

`moderate/scripts/ask-question.sh` computes the day count as:

```sh
asked_today=$(count_log_prefix human-checkin-ask "")
```

and `count_log_prefix` calls `log-read.sh --step-prefix human-checkin-ask` with **no day bound**. `log-read.sh` walks every day file under `.workaholic/moderations/` (it reported `"days": 5`), so the value named `asked_today` is the all-time total.

## Why it matters

The count crossed the cap of 10 on 2026-08-27 and the log is append-only and never pruned by a machine, so the value only ever grows. From that moment the check-in refuses every question forever, under a reason -- `day_cap`, `hold: true` -- that reads as a deliberate bound rather than as a mechanism that has stopped. `/moderate` is the one surface in this plugin that names a person, so the loop currently has no path from a finding to a human at all.

## The shape of the repair

Bound the count to the quiet-hours timezone day, the same zone the `quiet_hours` and working-day gates already read (`WORKAHOLIC_QUIET_TZ`, default `Asia/Tokyo`) -- one derivation of "today", not a second. `log-read.sh` already accepts a day, so this is a bound passed rather than a new reader. The per-tick cap, the asked-once gate and `hold: true` are untouched.

Reported by the 20260828-005129 tick of `/moderate`, which could ask none of its five questions.
