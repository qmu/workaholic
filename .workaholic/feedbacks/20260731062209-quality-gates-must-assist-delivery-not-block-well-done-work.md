---
type: Feedback
title: Quality gates must assist delivery, not block well-done work
kind: instruction
source: slack
created_at: 2026-07-31T06:22:09+00:00
author: noreply@anthropic.com
supersedes: 
---

# Quality gates must assist delivery, not block well-done work

Reported by tamura_yoshiya in Slack (#dev-workaholic), filed as
[qmu/workaholic#117](https://github.com/qmu/workaholic/issues/117). Recorded in the
reporter's own words.

## The instruction

The quality gates this plugin generates are too often blocking legitimate agent work rather than guiding it, and they need to be revised so that a gate reflects whether the work is actually done rather than whether the work happened to be authored in the exact shape the gate's tooling expects.

The concrete case that surfaced this: a mission's seven acceptance items were written in prose without the `(#artifact)` markers that `tick-acceptance.sh` keys on, so the script could tick none of them and the progress board stayed pinned at `0/7` even though every item was satisfied. The driver correctly refused to hand-edit `[x]` because the mission's own discipline forbids it, so the completed work is stranded showing zero progress — the gate punished a valid authoring choice instead of measuring completion.

This is the pattern to fix generally: gates whose green depends on a marker convention, a file location, or a formatting shape will keep firing false negatives on well-done work and forcing either a discipline violation or a stuck board. The direction to explore is making acceptance ticking able to resolve prose items (or otherwise decoupling "is this satisfied" from "does it carry the marker"), and more broadly auditing the gate set so each one blocks only on a real quality failure, not on a shape mismatch.

## The open question the reporter left

Whether the marker requirement should be relaxed in the ticker, enforced at authoring time so a markerless acceptance item can't be written, or replaced with a satisfaction check that doesn't depend on markers at all.
