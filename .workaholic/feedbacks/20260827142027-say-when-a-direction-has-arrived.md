---
type: Feedback
title: Say when a direction has arrived
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T14:20:27+00:00
author: a@qmu.jp
supersedes: 
---

# Say when a direction has arrived

Source: https://github.com/qmu/workaholic/issues/658

The `[Propose]` routine, judging the strategy `an-autonomous-improvement-loop-run-by-the-routines`, asks for the direction layer to gain a reading for **arrival**, and a seam that tells the operator once when a direction looks finished.

Every reading the direction layer has answers *is this direction in trouble* — `pace: late`, `overdue`, `dormant`, `unreadable`. None answers *has it arrived*. So a direction that produced its work and has nothing left in flight is indistinguishable from one still running, and on the day its `target_date` passes the loop reports that success as an hourly `direction-overdue` question addressed to the person who set the direction.

What is asked for:

- **`quiescent`** on every `survey-strategies.sh` row, eligible and refused alike — `true` exactly when the row is readable, `active`, `mine`, carries non-empty `feedback_refs`, has a **non-empty** `landed[]`, has `waiting_missions + waiting_count == 0`, and carries no open proposal. Every term is already on the row: no new counter, no field on any artifact, no second derivation. It carries **no date term at all**, deliberately: arrival is independent of the date, which is why it must outrank lateness. It is `dormant`'s complement on the one term that separates them — `landed` empty versus `landed` non-empty.
- **`arrived`** projected in `direction-state.sh`, which composes and never re-derives, at precedence `unreadable > arrived > overdue > dormant > live`. `arrived` above `overdue` because a direction whose work is all in is the operator's to close, whatever its date says, and naming a success as a failure is the defect this exists to remove.
- `/moderate`'s `step-direction-health.sh` asks the direction's assignee once, keyed `direction-arrived:<slug>`, naming what landed and the date — a description of the reading, never an assertion that the direction is finished, held to the same wording discipline `direction-dormant` already carries.

Two boundaries are the point of the change, not caveats on it. **The loop never closes a direction**: `close.sh` keeps its single-writer standing and its one caller, `/specificate`'s *ended* announcement route, and no reading here may reach it — the mission-grain archive gate closes on arithmetic (`checked == total`, queue empty) while a direction's own "Reached when" is prose no script reads, so `arrived` is a **candidate** and the operator's answer is the verdict. And **`quiescent` lifts and closes no gate**: an arrived direction stays eligible, `refusal`, `pace`, `overdue`, `dormant`, the sort and `selected` stay byte-identical, and `/propose` keeps proposing against it and merely *says* that it is doing so.

Why now: this strategy's own `target_date` is 2026-08-31, four days out, and its `Reached when` — a proposal opened by `[Propose]`, ingested by `[Specificate]`, driven by `[Implement]`, and visible back on the strategy through the attribution reader — was proved by the landed mission `prove-the-loop-s-closing-link`. On 2026-08-31 this direction, having done exactly what it set out to do, starts producing an hourly `direction-overdue` question — the loop reporting its own completed direction as a failure, correctly, by every gate.

Chosen against a `depth` mission sharpening the proposal judgement itself (mechanizing `reference/loop.md` step 3's lossy-`landed[]` rule). That one deepens a reading the loop already makes inside a lifecycle that works, and its failure mode is a slightly worse proposal, recoverable on the next turn; this one is a part of the direction layer's own life nothing has touched at all, with a failure mode arriving on a fixed date.

The ask names the mission it wants: a title, the experience it demands, and an ordered set of eight tickets.
