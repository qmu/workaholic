---
type: Feedback
title: Let a direction that finished early read as arrived
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T14:17:14+09:00
author: a@qmu.jp
supersedes: 
---

# Let a direction that finished early read as arrived

An observing AI session reports that the `arrived` verdict in `survey-strategies.sh` requires a direction's **age** to exceed the survey window in addition to its residue being drained, so a direction that genuinely finishes early cannot be reported as arrived — it stays `eligible` until its target date passes and then expires, and the expiry says nothing about whether the work was finished or abandoned.

Source: https://github.com/qmu/workaholic/issues/1026

## What the ask reports

Two independent `propose` runs on consecutive cycles in a consuming repository reached the same four directions and refused all four **by judgement**, because the mechanical verdict could not say what was true:

| Direction | Age | Days to target | Residue | Mechanical verdict | The run's judgement |
| --- | --- | --- | --- | --- | --- |
| A | 6d | 1 | `quiescent: true`, readable | `eligible` | `self_refining` — 85 landed; every clause of the originating ask has a landed mission |
| B | 6d | 1 | `quiescent: true`, readable | `eligible` | `self_refining` — 69 landed; the undeclared entries are questions the specification leaves open on purpose |
| C | 7d | — | `quiescent: true`, readable | `eligible` | `no_evolutionary_move` — 153 landed, every named deliverable implemented |
| D | 7d | — | `quiescent: true`, readable | `eligible` | `no_evolutionary_move` — the remaining step already exists as a queued ticket |

All four are 6-7 days old against a 14-day window, and the residue half of the test already passes for every one of them.

## Why the age term does not do what it protects against

The hazard it presumably guards is calling a *young* direction arrived because nothing has been attributed to it yet — quiet because it has not started, not because it finished. The ask argues age is the wrong proxy: a direction with 153 landed artifacts and a drained residue differs from one with zero landed artifacts in exactly the fact that matters. Gating on landed work would refuse the never-started direction while admitting the early finisher; gating on the calendar refuses both.

## The consequence the ask names

Two of those directions reach their target date the next day. With `arrived` unreachable, the only outcomes are *extend the date* or *let it expire* — neither true when the work is done, and either one records the wrong reason for the ending. For an unattended loop it is worse: the run cannot act on its own correct judgement, which survives only in a run report nothing reads afterwards.

## What it asks for

- Replace the age term with a landed-work term in the `arrived` test: a drained residue plus a non-empty attributed corpus.
- If the age term must stay, give the run a way to record an early arrival (or to close on judgement with the evidence attached) rather than forcing every early completion through extend or expire.
- Report the age term when it is what held the verdict — `eligible` beside `quiescent: true` gives no hint that a second, unrelated condition is blocking `arrived`, and both runs had to read the script to find out.

## How this run judged it

**Record-only, `self_authored`.** The ask carries `subject: observer_ai:tamura.yoshiya@gmail.com`, so `feedback/scripts/ask-origin.sh` reads `machine`; its subject is the loop's own apparatus — `/propose`'s own eligibility survey. `plugins/workaholic/rules/workaholic.md`, *What May Originate a Mission*, is explicit that such a record may not originate a mission. The finding is kept as knowledge; a human ask naming this work is what would originate it.
