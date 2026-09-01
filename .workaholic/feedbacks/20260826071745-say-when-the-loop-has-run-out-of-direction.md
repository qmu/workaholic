---
type: Feedback
title: Say when the loop has run out of direction
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-26T07:17:45+00:00
author: a@qmu.jp
supersedes: 
---

# Say when the loop has run out of direction

Source: https://github.com/qmu/workaholic/issues/617

The `[Propose]` routine asks that the loop say when it has run out of direction.

Every mission attributed to the strategy `an-autonomous-improvement-loop-run-by-the-routines`
so far has been about the **turn** — a proposal opened, ingested, driven, and made visible back
on the direction it came from. The turn works and is pinned by a hermetic test. Nothing has
touched the **direction's own life**: what the loop does when a direction is finished, when it
has run past its date, and when the repository holds no live direction at all. In each of those
states the loop goes quiet in exactly the way a healthy idle hour goes quiet, so the layer the
developer was promoted to has no signal at all.

Three states are silent today, each for its own reason:

- **A direction past its `target_date`.** `survey-strategies.sh` refuses it `past_target_date`
  and stops. `pace` cannot carry it: `late` requires `landed == 0`, so a direction that sailed
  past its date **while producing work** reads `on_course`, is refused for a correct reason, and
  produces no proposal and no question, forever. `step-strategy-pace.sh` asks only about `late`.
- **A live, in-date direction nothing is answering.** A tick that can name no move reports
  `no_evolutionary_move` into a run report that on the day it matters is read by nobody.
- **A repository with no live direction at all.** `no_strategies` is a reason to post nothing
  everywhere: `standup/scripts/digest.sh` no-ops it, `/moderate`'s `strategy-digest` rides
  nothing on the root, `/propose` reports it to its own run report. An empty direction layer is
  byte-identical, on every surface, to a quiet healthy hour.

What must become true: each of the three has a **named reading**, derived from what the survey
already computes; the person who owns the direction is **asked once** about it through the
tick's existing check-in; and the loop's silence is never again indistinguishable from its
health.

Three refusals are stated as part of the ask, not omissions from it. The loop **asks; it never
closes** — a strategy carries no acceptance list and its progress is not computed, so
`achieved` can never be arithmetic the way a mission's is, and `close.sh` stays reachable only
through the operator's own announcement. **No artifact gains a field** and no relation is added;
every reading composes `survey-strategies.sh`, the reader that already exists. **`/standup`'s
`no_strategies` no-op is deliberately untouched** — a digest about nothing teaches its readers
to skip the surface, which is why the reading goes to the question surface.

The ask names the strategy's own urgency: `2026-08-31` turns that strategy into the first
`past_target_date` direction this loop has ever held, five days out.

The ask arrives with a mission already planned — a title, the experience it demands, and an
ordered set of eight tickets.
