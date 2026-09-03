# The record behind the tick

The measurements, the rejected alternatives and the history behind
`plugins/workaholic/commands/infinite-development.md`. **Nothing here is operative.** A run applying
a rule needs the rule, which stays in the command; a person deciding whether to *change* a rule needs
this, and paying for it on every five-minute tick of a session that never resets is what this split
removed.

**Why the split exists** (2026-09-03, mission `pay-only-the-operative-cost-on-every-tick`). The
command body was 1,775 words / 11,291 bytes, re-paid every tick. `workaholic:notify` states that
*the command is the ceiling*, and the routine-template rule (2026-09-02, ticket `20260902043747`)
says a rule the run must **read to act** is inlined byte-identical while a **provenance citation**
stays a citation. So what moved is the record; **no operative instruction moved**, and nothing was
replaced by a summary — a paraphrased ceiling is a third version of the rule.


## Why the checkout is read, and why the tick does not commit it

It **blocks nothing and commits nothing**. The tree belongs to a person, half-finished work is
the normal state of one, and a loop that commits what it finds lying around is a worse failure
than the one it would cure. Measured 2026-09-03: an entire change — this command's own first
version, the retirement it performed, and the environment declaration beside it — sat
uncommitted in the loop's checkout across every tick of its first hour, driving the loop's
behaviour the whole time, and no step anywhere was looking at it.

## Why an idle subagent is reaped at the spawn

A tick that skips this leaves one corpse per tick in the very listing
the concurrency rule has to read, and the next spawn cannot even take its own name (measured
2026-09-03: three ticks, three idle `propose` agents, the third spawned as `propose-3`).

## Why `propose` carries a cadence and `implement` does not

writes an ask — neither of which happens inside five minutes. Measured 2026-09-03: three
consecutive ticks, three full agent runs, every one answering `work_waiting` / `nothing_in_hand`
and writing nothing anywhere. A cadence is the honest bound and a change-detector is not —
*has the queue moved* is a second derivation of the gate `/propose` already owns, and this
repository keeps one rule in one place. `0` means every tick.

## Why a run's result reaches the parent once

**A run's result reaches the
parent once**: the idle notification always arrives, so a subagent must not also be asked for a
summary message — measured once in this session as a thirty-one step table delivered twice into
the parent's context, the notification and the summary carrying substantially the same content.
The notification is the one that cannot be turned off, so it is the one that stays.

## Why a quiet tick says one line

  own report. Measured before this: the majority of a session's ticks had nothing to say and still
  printed four to six lines of `still_running` / `not_due`.
