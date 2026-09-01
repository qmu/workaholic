---
type: Feedback
title: Deliver what the loop already knows to the person who can act
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-28T12:17:29+00:00
author: a@qmu.jp
supersedes: 
---

# Deliver what the loop already knows to the person who can act

Source: https://github.com/qmu/workaholic/issues/687

The `[Propose]` routine, reading the strategy `an-autonomous-improvement-loop-run-by-the-routines`, asks for a **contraction**: the loop's one path from a machine finding to a person is jammed shut, and nothing in the loop can tell.

## What was asked

Three things must become true.

**"Today" is derived once.** `moderate/scripts/ask-question.sh` computes `asked_today=$(count_log_prefix human-checkin-ask "")`, and `count_log_prefix` calls `log-read.sh --step-prefix human-checkin-ask` with **no day bound** — so `log-read.sh` walks every day file under `.workaholic/moderations/` and the value named `asked_today` is the all-time total. It crossed `max_per_day` on 2026-08-27, the log is append-only and a machine never prunes it, so the count only ever grows and every question is refused `day_cap` forever. Bind it to the `WORKAHOLIC_QUIET_TZ` day the `quiet_hours` and working-day gates already derive — a bound passed to a reader that already accepts one, not a second reader and not a second notion of a day. The per-tick cap, `already_asked`, `answered` and `hold: true` do not move.

**A multi-day backlog drains in urgency order, under the existing per-tick cap.** Fifteen findings are held right now — 7 `undrivable-unit`, 3 `retire-blocked`, 1 `handoff-unit`, 1 `direction-dormant`/`direction-last`, 1 `stalled-unit`, 1 `stuck` — and unbinding the count without an order would land them as one wall. Ask oldest-held first, still bounded by `max_per_tick`, so the arrears arrive over several ticks in the order they went stale.

**A check-in that delivered nothing is a named state, not `ok`.** The step reports `ok — up to 5 questions may be asked this tick; 14 held from an earlier tick` and the tick posts nothing, because the root's gate is *a question* and there were none. Eight consecutive ticks read exactly like eight quiet hours. The check-in must read back what it delivered and what it held, distinguish a cap genuinely spent today from a mechanism that has stopped, and carry that reading somewhere a person sees.

## Why it commits to the direction

The Aim's own words: *"The loop is a machine with a human-shaped hole in it."* That sentence was written about the ask coming **in**, and the direction closed that hole. The hole did not close; it moved to the other end. Seven question-producing steps shipped against this Aim in the last eleven days — `stalled-units`, `undrivable-units`, `undelivered-units`, `handoff-units`, `retire-claims`' blocked-act question, `base-health`, `direction-health` — and every one of them has been computing correctly into a gate that refuses on arithmetic. The base has been red at `validate` since at least 09:52 UTC with nobody told; a declared verification handoff has sat on PR #647 for 31 hours with nobody told; three proved-empty claims cannot delete their branches with nobody told; seven queued units are owned by an address the identity mapping does not name, which is one line of repair with nobody told.

## What it is chosen against

The rival is the **breadth** move: claim the residue — four active missions and one loose queued ticket belong to no direction. It loses because it is downstream: three of those four missions are blocked on exactly the channel this repair fixes. Driving them means asking their owner something, and asking is the thing that does not work.

The honest counter-case is stated in the ask and answered by it: a cap on questions exists for a reason this repository has learned twice (`🔧 Needs a decision` and `📦 Release Preparation` were retired for spending a person's attention on restatement), and unbinding the count without an order could put fifteen mentions in one thread. That is why the drain is ordered and stays under `max_per_tick`, and why a spent cap must still read as spent. The bound is kept; only its arithmetic and its silence are wrong.

## The plan the ask named

Seven tickets, in order: reproduce and pin the jam; bound the day count to the quiet-hours day; drain a multi-day backlog in urgency order; read what the check-in delivered and held; make a tick that reached nobody a visible event; state the cap's contract where the step is documented; drill the delivery path end to end with no network.
