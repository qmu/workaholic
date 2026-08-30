---
type: Feedback
title: Warn a direction before its date silences the loop
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T02:17:12+00:00
author: a@qmu.jp
supersedes: 
---

# Warn a direction before its date silences the loop

The [Propose] routine asks for a reading of the one event that silences the loop and that nothing currently sees coming: a direction's target_date arriving.

Source: https://github.com/qmu/workaholic/issues/695

Every reading in the direction layer answers backwards. `pace: late` says nothing landed;
`overdue` says the date already went; `dormant` says nothing is answering; `arrived` says the
work is all in. None answers *this direction is about to stop originating work*, so
`past_target_date` — a hard refusal that silences origination exactly as `not_active` does —
arrives with no warning at all, and the only signal is `direction-overdue`, asked once, in
arrears.

Measured on the strategy `an-autonomous-improvement-loop-run-by-the-routines` at the time of
the ask: `days_to_target: 2`, `pace: on_course`, `overdue: false`, `dormant: false`,
`quiescent: true` — every reading healthy, and two days from `past_target_date` refusing every
proposal. The direction whose Aim is that the loop runs itself is silenced by the one part of
itself nobody looks at.

The ask names the shape: `survey-strategies.sh` emits `expiring` on every surveyed row,
`true` exactly when `days_to_target != null and 0 <= days_to_target <= $window_days` — no new
threshold, both terms already on the row, its own field and never a fourth `pace` value;
`direction-state.sh` ranks it in the fixed precedence and carries the leaving onto it;
`/moderate`'s `direction-health` asks the assignee once, before the date, under every existing
gate; `/propose` names it in the run report as evidence. Nothing is re-dated, closed, amended,
gated, sorted or proposed differently, and the strategy artifact keeps its three writers.

The precedent is `direction-last:<slug>`, which names the last live direction to its owner
while they can still act rather than announcing silence afterwards to nobody. Expiry is the
same event by a different cause, and it is uncovered.
