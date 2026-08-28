---
type: Feedback
title: Deliver what the loop already knows to the person who can act
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T18:16:39+00:00
author: a@qmu.jp
supersedes: 
---

# Deliver what the loop already knows to the person who can act

The [Propose] routine asks that the loop deliver what it already knows to the person who can act on it.

Source: https://github.com/qmu/workaholic/issues/687

The check-in gate that carries every machine finding to a human has jammed shut, and
nothing in the loop can tell. Three things must become true.

1. "Today" is derived once. `moderate/scripts/ask-question.sh` computes
   `asked_today=$(count_log_prefix human-checkin-ask "")`, and `count_log_prefix` calls
   `log-read.sh --step-prefix human-checkin-ask` with no day bound — so the reader walks
   every day file under `.workaholic/moderations/` and the value named `asked_today` is the
   all-time total. It crossed `max_per_day` on 2026-08-27; the log is append-only and a
   machine never prunes it, so the count only ever grows and every question is refused
   `day_cap` forever. Bind it to the `WORKAHOLIC_QUIET_TZ` day the `quiet_hours` and
   working-day gates already derive — a bound passed to a reader that already accepts one,
   not a second reader and not a second notion of a day.

2. A multi-day backlog drains in urgency order, under the existing per-tick cap. Fifteen
   findings are held: 7 `undrivable-unit`, 3 `retire-blocked`, 1 `handoff-unit`, 1
   `direction-dormant`/`direction-last`, 1 `stalled-unit`, 1 `stuck`. Unbinding the count
   without an order would land them as one wall, so ask oldest-held first, still bounded by
   `max_per_tick`.

3. A check-in that delivered nothing is a named state, not `ok`. The step reports `ok — up
   to 5 questions may be asked this tick; 14 held from an earlier tick` and the tick posts
   nothing, because the root gate is a question and there were none. Eight consecutive ticks
   read exactly like eight quiet hours.

Consequences measured at the time of the ask: the base had been red at `validate` since at
least 09:52 UTC with nobody told; a declared verification handoff had sat on PR #647 for 31
hours with nobody told; three proved-empty claims could not delete their branches with
nobody told; seven queued units are owned by an address the identity mapping does not name,
which is one line of repair with nobody told.

The move is declared a contraction against the strategy
`an-autonomous-improvement-loop-run-by-the-routines`: the landed work made the check-in gate
inconsistent with the Aim — the more the loop learned to notice, the less it could say — and
the repair unifies the loop notion of a day onto the one derivation that already exists
rather than adding anything. It is chosen against the breadth mission beside it (claim the
unattributed residue), which loses because three of those four missions are themselves
blocked on exactly the channel this repairs.

The cap itself is kept. Only its arithmetic and its silence are wrong.
