---
type: Feedback
title: Refuse a tick id the log's own minter did not write
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T14:14:17+09:00
author: a@qmu.jp
supersedes: 
---

# Refuse a tick id the log's own minter did not write

An observing AI session reports that `log-append.sh` accepts any string as `--tick` and that `log-read.sh --latest-tick` orders lexically, so one caller passing a local-clock id (`date +%Y%m%d-%H%M%S` instead of `tick-id.sh`'s `date -u`) durably blinds every `--latest-tick` reader for the retention window.

Source: https://github.com/qmu/workaholic/issues/1024

## What the ask reports

Measured: `log-read.sh --step-prefix loop-finish-moderate --latest-tick` returned `latest_tick: "20260906-112449"` (a local-clock id) while the true newest finish in the day file was `20260906-041338`, over seven hours earlier on the UTC axis. `commands/infinite-development.md` gates the `moderate` loop on exactly that reader ("spawn it only when the newest tick there is older than 30 minutes"), so a future-dated id answers `not_due` for the rest of the day and the maintenance loop stops silently. The reader cannot tell a corrupted answer from a genuine recent finish: both are a well-formed id with `"read": true`.

## What it asks for

- Validate `--tick` at write time in `log-append.sh` (the one writer): refuse an id that is not `tick-id.sh`-shaped or is implausibly ahead of `date -u`, with a named reason such as `bad_tick_id`, rather than storing it.
- Order `--latest-tick` by the id's parsed instant rather than by string comparison.
- Consider a reported warning when a day file holds ids from more than one clock; never rewrite historical entries.

It names itself the **cause** of a separately reported consumer defect (the `blocked-tick` step picking its subject lexically), and states that fixing the consumer alone would leave this open.

## How this run judged it

**Record-only, `self_authored`.** The ask carries `subject: observer_ai:tamura.yoshiya@gmail.com`, so `feedback/scripts/ask-origin.sh` reads `machine`; its subject is the loop's own apparatus (the moderation tick log and the development loop's cadence gate). `plugins/workaholic/rules/workaholic.md`, *What May Originate a Mission*, is explicit that a record a routine wrote about the loop's own apparatus may not originate a mission. The capture is honest and the report is kept as knowledge; a human ask naming this work is what would originate it.
