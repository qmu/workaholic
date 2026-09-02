---
type: Feedback
title: A machine log must never land on the base, and the move must not wait for a human
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-09-02T04:19:34+00:00
author: a@qmu.jp
supersedes: 
---

# A machine log must never land on the base, and the move must not wait for a human

Source: https://github.com/qmu/workaholic/issues/857

Observed on a consuming repository, 2026-08-20 through 2026-08-31: the hourly ticks
committed their day log straight to the base — hundreds of "Log the propose tick" /
"Log the moderation tick" commits, 12 day files, roughly 7,000 lines — until the
operator ran `/workaholify` by hand on 2026-09-02. Only then did
`migrate-moderations-off-main.sh` seed the log branch and stage the base-side removals,
and the operator still had to commit and merge that staging themselves.

The gap: the off-main log design (issue #782) reaches a consuming repository only
through `converge-layout.sh`, so between the plugin shipping the design and a human
running the preparation command, every tick fired from a container carrying the older
plugin kept writing to the base — silently, hourly, with nothing in the loop flagging
the accumulation.

The operator instructs that this class of failure be made impossible, not merely
cleaned up:

1. A machine log must never land on the base. `persist-log.sh` (and any future log
   writer) should refuse the base as a destination outright, rather than the base
   being merely the pre-migration default.
2. The migration must not wait for `/workaholify`. The tick that owns the log already
   reaches the network (`ensure-log-ref.sh` creates the branch); when it finds day
   files still tracked on the base it should either complete the move itself or raise
   a per-tick finding until a person acts — twelve days of silent accumulation is the
   defect, the leftover files are only its residue.
3. The propose tick's log lines rode the same day files to the base under their own
   commit messages; whatever guard is added must cover every writer of the tick log,
   not the moderation tick alone.
