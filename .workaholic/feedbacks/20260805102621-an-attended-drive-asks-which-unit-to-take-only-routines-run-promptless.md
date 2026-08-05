---
type: Feedback
title: An attended /drive asks which unit to take; only routines run promptless
kind: instruction
source: discussion
created_at: 2026-08-05T10:26:21+09:00
author: a@qmu.jp
supersedes: 
---

# An attended /drive asks which unit to take; only routines run promptless

Ruled by the developer on 2026-08-05, amending decision G1's 'no drive-time confirmation of any kind'. An ATTENDED /drive — a developer typing the command — asks which unit(s) to take when the survey offers more than one claimable or resumable target, via one AskUserQuestion listing the partition; a single target, or an explicit instruction naming one, proceeds without asking. The UNATTENDED shape — the [Drive] routine and any headless caller — keeps the current zero-prompt path exactly, selected by an explicit invocation form rather than inferred (the routine's prompt names it). The partition stays reported in full either way; what changes is only who picks when a person is present to pick. This closes the failure measured on 2026-08-05 morning: the survey's resumable-first ordering overrode the operator's actual WIP twice in one attended run, and the developer had to interrupt to ask why. The ordering fix (parked_with_pr) shipped; this rules the remaining half — an attended run defers the CHOICE to the person, not just the ordering to a heuristic.
