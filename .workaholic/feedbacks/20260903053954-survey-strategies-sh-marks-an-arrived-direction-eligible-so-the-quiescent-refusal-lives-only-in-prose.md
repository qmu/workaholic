---
type: Feedback
title: survey-strategies.sh marks an arrived direction eligible, so the quiescent refusal lives only in prose
kind: insight
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-03T05:39:54+09:00
author: a@qmu.jp
supersedes: 
---

# survey-strategies.sh marks an arrived direction eligible, so the quiescent refusal lives only in prose

Source: https://github.com/qmu/workaholic/issues/920

`survey-strategies.sh` does not implement the quiescent refusal, so the 2026-09-02 ruling holds
only for as long as each run remembers to apply it by hand.

## What was observed

A /propose run surveyed eight strategies in a repository running this loop. Five were active,
four came back `work_waiting`, and the fifth came back `eligible` and `selected` while its own
row on the same survey carried `quiescent: true` - work landed against it, nothing waiting, the
residue read successfully and empty. The run refused it anyway, citing the skill ruling that an
arrived direction refuses origination, and reported `no_evolutionary_move`. Had it trusted the
survey it produced rather than re-reading the skill text, it would have opened a mission against
the one direction with the least work waiting for it, which is the failure that ruling was
written down to stop.

## Why this is worse than a duplicated check

`commands/propose.md` says every gate is mechanical and names `arrived` in that list, and it is
the one member of the list the script does not enforce. So the sentence reads as a description
of the survey and is not one. What stands between the ruling and the behaviour is a run
willingness to overrule its own tooling.

## What the reporter asked for

That `survey-strategies.sh` refuse a quiescent row itself, with a reason of its own, so
`eligible` and `selected` never name a direction the command must then refuse in prose. The
landed count, the waiting count and the residue read are already on the row it returns; only the
verdict is missing.

## Why this record warrants no work

The ask carries `subject: observer_ai:`, so no person wanted it, and its subject is the loop own
apparatus - `survey-strategies.sh` and the /propose gate ladder. `rules/workaholic.md`, *What May
Originate a Mission*, says only a human ask or a human-authored strategy may originate one. The
finding is kept here as knowledge for a person to read and act on; it is not proposed.
