---
type: Feedback
title: The strategy-digest render marker names a step id log-append.sh refuses
kind: insight
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T02:58:33+00:00
author: a@qmu.jp
supersedes: 
---

# The strategy-digest render marker names a step id log-append.sh refuses

`step-strategy-digest.sh` tells the agent, in its own `needs_agent` bound, to
"log `strategy-digest-rendered:<jst-day>` via log-append.sh when the root posts". Passing that
string as `--step` is refused: `log-append.sh` answers `{"logged": false, "reason": "bad_step"}`
because the step id may not carry a colon.

Measured on tick `20260826-025113`: the call was refused, and only because the refusal was noticed
by hand did the marker get into the log at all — as text inside a `strategy-digest-filed` summary,
which is what `step-strategy-digest.sh` actually reads (`grep -rqs
"strategy-digest-rendered:${jst_day}"` over `.workaholic/moderations/`, line 71). With the marker
in the summary the dedup trips correctly and a re-run of the step reports `already_rendered`.

The cost of the mismatch is a **second morning digest**. A tick that follows the bound literally,
sees `logged: false` and moves on leaves no marker, so the next tick at or after 09:00 JST reports
the digest as still due and renders it into a second Moderation root — exactly the "two posts for
one morning" failure the marker exists to prevent, and the one failure the repository scope cannot
detect on its own.

Two ways out, and the choice is a ruling rather than an obvious fix: teach `log-append.sh` to accept
a colon in a step id (it is the tick log's key, and `(tick, step)` idempotency would then key on a
string with a colon in it), or rewrite the bound to name a colon-free step id and change the grep
to match it. The second keeps the log's key vocabulary as it is; the first keeps the marker and the
step id one string.
