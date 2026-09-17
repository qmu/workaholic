---
type: Feedback
title: Distinguish an attribution ruling from a routine feedback append
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-08T19:08:17+09:00
author: a@qmu.jp
supersedes: 
---

# Distinguish an attribution ruling from a routine feedback append

The operator's asked-for behaviour is to gather feedback that arrived together into one mission,
grow that mission as more arrives, and deliver at its completion. The publication-refusal rule
punishes exactly that behaviour.

`branching/scripts/lib/publication-refusal.sh` classifies a publication as `ruling_touching` when
a mission that already existed on the base (`M`) has its `feedback:` line moved by the diff. The
aim is right: an attribution ruling written by `carry-attribution.sh` is the operator's to make.
What the rule misses is that two different acts move that line and their diffs are shaped alike —
the attribution ruling (a person's judgement) and `/specificate` appending a feedback ref while it
extends an existing mission (ordinary routine work). The second is caught by the first's test, so
its auto-merge stops.

The incentive is inverted as a result. Minting a new mission sails through; growing an existing
one halts awaiting a person's ruling. The more the loop does what the operator wants, the more
work is handed back to a person; the fragmentation the operator dislikes flows without friction.

Measured 2026-09-08 on this repository: PR #1097 and #1094, each adding a single `feedback:` ref
to the existing mission `make-slack-intake-incremental-across-messages-threads-and-mentions`, were
held `ruling_touching` for five hours while `main` moved under them and conflicted. PR #1112,
minting a new mission in the same window, landed in four minutes. Secondary damage: while it was
held, the target mission was archived `achieved`, so #1094 had nowhere to land and was closed as a
duplicate — `close.sh` is the only writer of an end state and offers no re-open path.

The conflicts went unresolved for the same root cause. `settle-stranded-publication.sh` can settle
`mechanical`, `clean` and `content` classes, but `list-stranded-publications.sh` deliberately
excludes every pull request `list-operator-facing-pulls.sh` claims (its term 3), so a publication
falls out of every catch-up path the moment it is classified `ruling_touching`, and its conflict
deepens each time the base moves.

What is asked: make the attribution ruling `carry-attribution.sh` writes distinguishable from a
`/specificate` feedback append. The rule's aim — an attribution ruling is a person's — need not be
loosened. The gap is that "did the `feedback:` line move" is not enough evidence on its own.

Source: https://github.com/qmu/workaholic/issues/1119
