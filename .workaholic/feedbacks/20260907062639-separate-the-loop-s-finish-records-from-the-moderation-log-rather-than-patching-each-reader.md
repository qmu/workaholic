---
type: Feedback
title: Separate the loop's finish records from the moderation log, rather than patching each reader
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-07T06:26:39+09:00
author: a@qmu.jp
supersedes: 
---

# Separate the loop's finish records from the moderation log, rather than patching each reader

Source: https://github.com/qmu/workaholic/issues/1059

Separate the loop's `loop-finish-*` lines from the moderation tick log, rather than
patching each reader the mixing breaks.

## What was measured

`/infinite-development` records each subagent finish with
`log-append.sh --step loop-finish-<name>`, under the **coordinator's** tick id, into
`.workaholic/moderations/<UTC-day>.md` — the same file `/moderate` writes its own steps
into. Each such write opens a `## <tick-id>` section that carries no moderation rows.

Two readers of that file are now known to break on it:

1. **The cadence gate** (`commands/infinite-development.md` §2, `log-read.sh --latest-tick`)
   — repaired for `moderate` specifically by PR #1056, ticket `20260907031134`.
2. **The change baseline** (`moderate/scripts/render-tick-post.sh`, the previous-section
   selection) — **not repaired**. It selects the previous *section* as the baseline.
   Measured at tick `20260906-211606`: the previous section was `20260906-210558`, holding
   one `loop-finish-implement` line and nothing else, so the baseline carried no comparable
   rows and the renderer answered **`no_rows`**, falling out before the post gate was
   reached.

Counts on 2026-09-06: **82** `loop-finish-*` lines, **0** `human-checkin-post` lines.

## Why it matters

The Slack channel is currently unreadable from the loop's sessions, so nothing is being
posted and the defect is invisible. When the transport is restored the `🔎 Moderation`
root will still carry no change lines: the renderer keeps answering `no_rows` for as long
as the coordinator writes into that log more often than `/moderate` runs — which is
always, a five-minute tick against a thirty-minute one.

## The shape asked for

Two readers have broken on the same cause, which is the argument for repairing the cause
rather than the readers. Either:

- give the loop's finish records their own namespace — a separate day file, or a marker
  the moderation readers filter on — so `/moderate`'s log holds only `/moderate`'s
  sections; **or**
- make the baseline search skip sections carrying no moderation rows, the way the cadence
  reader now keys on its own step prefix.

The first is preferred if it can be done without a second store: the log carries whatever
any writer puts in it, and every future reader inherits the same trap otherwise.

Whichever is chosen: `log-append.sh` stays the one writer, the log stays git-ignored and
stays in the checkout that wrote it, and no cursor or second store is added.

## Non-goals

Do not stop the tick recording its finishes — the cadence depends on them and they are
correct where they are. Do not prune the existing lines: the log is append-only, and a
machine deleting lines it dislikes is a worse failure than the one it would cure.
