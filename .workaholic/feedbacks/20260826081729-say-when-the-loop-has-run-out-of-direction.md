---
type: Feedback
title: Say when the loop has run out of direction
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-26T08:17:29+00:00
author: a@qmu.jp
supersedes: 
---

# Say when the loop has run out of direction

Source: https://github.com/qmu/workaholic/issues/617

Opened by the `[Propose]` routine against the strategy `an-autonomous-improvement-loop-run-by-the-routines` (move: breadth).

## What is asked

Make the loop say when it has run out of direction. Every mission attributed to this strategy so far has been about the **turn** — a proposal opened, ingested, driven, and made visible back on the direction it came from. Nothing has touched the **direction's own life**: what the loop does when a direction is finished, when it has run past its date, and when the repository holds no live direction at all. In each of those states the loop goes quiet exactly the way a healthy idle hour goes quiet, and the layer the developer was promoted to has no signal at all.

Three states are silent today, each for its own reason:

- **A direction past its `target_date`.** `survey-strategies.sh` refuses it `past_target_date` and stops. `pace` cannot carry it: `late` requires `landed == 0`, so a direction that sailed past its date **while producing work** reads `on_course`, is refused for a correct reason, and produces no proposal and no question, forever. `step-strategy-pace.sh` asks only about `late`, so nobody is told.
- **A live, in-date direction nothing is answering.** A tick that can name no move reports `no_evolutionary_move` — the honest answer — into a run report that on the day it matters is read by nobody.
- **A repository with no live direction at all.** `no_strategies` is treated everywhere as a reason to post nothing. An empty direction layer is byte-identical, on every surface, to a quiet healthy hour.

What must become true: each of the three has a **named reading**, derived from what the survey already computes; the person who owns the direction is **asked once** about it through the tick's existing check-in; and the loop's silence is never again indistinguishable from its health.

## Three refusals stated as part of the ask

The loop **asks; it never closes** — a strategy carries no acceptance list and its progress is not computed, so `achieved` can never be arithmetic the way a mission's is, and `close.sh` stays reachable only through the operator's own announcement. **No artifact gains a field** and no relation is added; every reading composes `survey-strategies.sh`, the reader that already exists. **`/standup`'s `no_strategies` no-op is deliberately untouched** — a digest about nothing teaches its readers to skip the surface, which is why the reading goes to the question surface, the one designed to be addressed to a person.

## Why it commits to the strategy

The Aim's closing paragraph says what the developer's new layer is: *what a person supplies is no longer the ticket but the direction — an Aim, a Schedule, an Assignee — and enriching that is the work that is left.* Everything landed so far enriches the turn, not the direction, so the Aim holds only while a live direction happens to exist. The ask is live for this repository in five days, when `2026-08-31` turns this strategy into the first `past_target_date` direction the loop has ever held.

## What it was chosen against

Depth on the attribution reader — closing the residue `attributed-work.sh` admits it cannot see. Refused because it improves the fidelity of a reading at a moment when the problem is that no reading reaches anybody. Two narrower alternatives are refused by name in the ask: letting the loop close an achieved direction on its own arithmetic (a strategy has no acceptance list, so the arithmetic does not exist), and rendering the empty-direction state on `/standup`'s morning digest (a digest about nothing teaches its readers to skip).

## The plan the ask names

Eight tickets, in order: the `overdue` reading on `survey-strategies.sh`; the `dormant` reading; `strategy/scripts/direction-state.sh` as the one lifecycle reader; the `/moderate` step `direction-health`; making the question actionable in its own body; rendering the reading on the `🔎 Moderation` root; a hermetic test pinning the three refusals; and `scripts/e2e/loop-drill.sh verify-direction-health`.
