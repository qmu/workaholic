---
type: Feedback
title: Every markerless acceptance item in this repo belongs to a proposed draft
kind: concern
source: discussion
created_at: 2026-07-31T06:23:05+00:00
author: noreply@anthropic.com
supersedes: 
---

# Every markerless acceptance item in this repo belongs to a proposed draft

Measured while registering [qmu/workaholic#117](https://github.com/qmu/workaholic/issues/117),
to check whether the stranded `0/N` board is an authoring-style problem or a structural one.
It is structural.

(Recorded with `source: discussion` because `create.sh` still rejects `source: development`,
the value the schema documents for a development-born concern — the defect already on record in
`20260730110715-the-sanctioned-feedback-writer-rejects-the-source-97-of-records-use.md`.)

## What the tooling requires

`tick-acceptance.sh` is the only sanctioned writer of an acceptance `[x]` (`mission/SKILL.md`'s
script table). Within `## Acceptance` it flips an item only when the line contains the literal
`(#<artifact-filename>)` marker; anything else returns `no_unchecked_match`. `progress.sh`
derives `checked/total` from the boxes, so an item no script can flip pins the mission's
progress for good. `validate-mission.sh` requires at least one checklist item on an `approved`
mission but never requires the marker — so nothing at write time prevents an item the ticker
can never reach.

## What the repository actually contains (2026-07-31)

| Missions | Acceptance items | Carrying a `(#...)` marker |
| --- | --- | --- |
| 4 archived (interrogation-authored) | 19 | 19 |
| 3 active (`/propose`-scaffolded) | 24 | 0 |

The split is total, and it is not stylistic. All three active missions were written by
`propose/scripts/scaffold-draft.sh` — `author: noreply@anthropic.com`, a populated `feedback:`
list, and `tickets: []`. A draft is proposed *before* any ticket exists, so at that moment
there is no filename to put in a marker. `mission/SKILL.md` already names this ordering ("the
writing order differs from the asking order") and expects approval or replan to emit the ticket
set and link the items.

## Why it strands work rather than merely delaying it

`missions/active/adopt-a-git-flow-branching-model-with-durable-ship-records/mission.md` is
already `status: approved` with `merge_policy: auto`, and it still carries `tickets: []` and 8
markerless items. Its board reads `0/8` and no sanctioned script can move it: the proposing
seam could not write the links, the approving seam did not backfill them, and hand-editing
`[x]` is forbidden by the mission's own discipline. The reporter's "gate punished a valid
authoring choice" is, in this repo, more specific — the gate's only key is a link that the seam
which authors the item is structurally unable to write.

## What this implies for the fix

Relaxing the ticker alone would leave the missing links missing. The seam that turns a draft
into an approved mission with a ticket set is where the acceptance-to-artifact link is either
established or lost, so any fix that does not touch that seam will keep producing `0/N` boards
for every future proposal.
