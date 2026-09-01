---
type: Feedback
title: base-health never reads a base whose tip is a bookkeeping commit
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-31T20:28:54+00:00
author: a@qmu.jp
supersedes: 
---

# base-health never reads a base whose tip is a bookkeeping commit

Source: https://github.com/qmu/workaholic/issues/785

kind: instruction / source: development / subject: person:a@qmu.jp

Measured 2026-08-31 into 2026-09-01, on a consuming repository. Every `/moderate` tick
reported the same line — `base-health — degraded: base_unreadable:tip_no_checks`. Throughout,
the base was green: the most recent commit on `main` that any workflow ran on concluded
success, and every workflow run on `main` that day did. The base colour was never in doubt;
it was simply never read.

The loop commits to the base constantly and most of those commits touch only `.workaholic/`
— a tick log, a story index, a claim heartbeat. Every workflow in that repository carries a
path filter that deliberately excludes `.workaholic/`, each saying why in its own header: a
commit that only writes `.workaholic/` leaves the built artifact byte-identical, so
rebuilding and republishing it would spend Actions minutes to change nothing. That filter is
right. Its consequence is that the base tip is, most of the time, a commit no workflow ran
on — so `read-base-checks.sh` answers `unanswerable (no_checks)`, correctly and by its own
stated doctrine, which is not what this ask is about.

`drive/scripts/attribute-base-red.sh` reads the tip first and returns on an unanswerable one
before the walk begins: the `case` on the tip emits `unanswerable "tip_${RC_REASON}"`. The
backward walk exists only for the red case, to attribute which commit broke the base.
`step-base-health.sh` then renders that verbatim as `base_unreadable:tip_no_checks`, with the
honest sentence that a red base is indistinguishable from a green one this tick. So a
repository whose loop writes bookkeeping to its own base never gets a base reading at all,
and the step that exists to notice a broken base is dark exactly when it is busiest.

The distinction this rests on is that `unanswerable` is doing two different jobs at the tip
and only one of them is terminal. `no_checks` is a fact about the commit: nothing ran on it
and nothing ever will, and it has a defined answer one step back — the newest ancestor that
does carry checks — and the walk that finds it is already in this file. `reader_failed`, a
rate limit and a refused transport are facts about us; walking past those would be reporting
an older commit colour as though it were the tip, which is the failure the three-valued
reader exists to prevent, and they should stay terminal. Collapsing the two into one
`unanswerable` is what makes the whole reading unreachable.

What would settle it, stated as a shape to weigh rather than a menu: let a `no_checks` tip
continue into the existing backward walk under the existing `max_commits` bound, and report
the colour of the newest checked ancestor together with how far back it was — a green base at
`<sha>`, n commits behind the tip, is a different and more useful sentence than silence. Keep
every other `unanswerable` reason terminal. The bound already there is what keeps this
honest: a base where the walk runs out of room reports `bound_exhausted` rather than
guessing, exactly as it does today for the red case.
