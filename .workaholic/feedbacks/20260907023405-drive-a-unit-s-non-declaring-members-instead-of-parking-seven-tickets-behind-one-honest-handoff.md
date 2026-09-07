---
type: Feedback
title: Drive a unit's non-declaring members instead of parking seven tickets behind one honest handoff
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-07T02:34:05+09:00
author: a@qmu.jp
supersedes: 
---

# Drive a unit's non-declaring members instead of parking seven tickets behind one honest handoff

Source: https://github.com/qmu/workaholic/issues/1053

**Let a PR-unit drive the members that declare no verification handoff, and hand off only
the members that do.**

## What is measured, here, now

Mission `report-each-tick-in-the-originating-codex-chat` holds 7 queued tickets. Exactly
**one** of them declares a `verification_handoff:`:

- `20260906022907-prove-the-behaviour-in-the-operator-s-own-codex-chat.md` — a live run in
  the operator's own originating Codex chat. This is a genuine, verified external
  limitation and must keep its handoff.

The other **six** carry an empty `verification_handoff:` field and need nothing external:

- `20260906022855-select-the-loop-mode-from-measured-capabilities.md`
- `20260906022855-carry-the-loop-state-across-context-compaction.md`
- `20260906022855-retire-only-the-supervisor-the-native-mode-replaces.md`
- `20260906022855-delegate-each-due-role-as-a-bounded-native-child.md`
- `20260906022855-run-the-tick-as-a-native-parent-that-keeps-its-turn.md`
- `20260906022855-reserve-the-final-response-for-a-stop-or-a-refusal.md`

Under the current rule (*Any member declaring it — or deriving one — carries the whole
unit*), the one honest declaration parks all seven. The claim reads `awaiting_verification`,
the survey excludes it as `claimed_awaiting_verification`, `backlog_all_excluded` reports 7
with 0 offered, and `/propose` refuses every direction with `work_waiting` on that same
mission. The repository has therefore driven **zero** units for hours while six tickets that
need nobody sit behind one that needs a person.

## Why the current rule is not simply wrong

Whole-unit handoff was correct when the alternative was a run guessing which half of a unit
was safe. The proof discipline is what makes it safe, and that must not be given up: the
split has to be a **file test on the declaration**, never a judgement about what a ticket
"probably" needs.

## The shape asked for

A PR-unit whose members' declarations are mixed drives the non-declaring members and hands
off only the declaring ones — the handoff route applying to the members that earned it
rather than to the unit that contains them. Every existing refusal stays: a `probe:`
declaration still runs at claim time, a `blocking` probe still hands over, a prose
declaration is still verified here before it is honoured, and a unit whose members all
declare still takes the handoff route whole.

## Non-goals

Do not weaken the handoff itself, do not let a run declare or clear a declaration for its
own unit, and do not resolve the mission's own `content` conflict as part of this.

## Provenance

The operator's standing instruction in the running session of 2026-09-06 (*routine
engineering work must never be handed back to a person*; *not stopping is the first
priority*), filed as issue #1053 and assigned to `tamurayoshiya`.
