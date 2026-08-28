---
type: Mission
title: Make a direction's end a turn of the loop, not its stop
slug: make-a-direction-s-end-a-turn-of-the-loop-not-its-stop
status: active
merge_policy:
created_at: 2026-08-28T05:20:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828051826-make-a-direction-s-end-a-turn-of-the-loop-not-its-stop.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make a direction's end a turn of the loop, not its stop

## Goal

Every reading in the direction layer is bounded to `status: active`, so closing the last live
direction leaves the loop originating nothing: `/propose` refuses `not_active`, the inbox is
empty, and the only signal is `direction-none`, addressed to nobody. Make the boundary a turn
of the loop — and no machine ever authors, closes or drafts a direction.

## Experience

When the operator ends a direction they are not handed a blank page and the loop does not go
quiet. The closing pull request and `/moderate`'s question both state what it is leaving —
what it never reached, what no direction claimed, its last lifecycle reading — before the
decision, not after it. An announced successor carries the predecessor's own feedback refs, so
`attributed-work.sh` reads that predecessor's landed work and residue as the successor's from
its first hour and `/propose` resumes on the next tick. The strategy artifact still has exactly
three writers and no artifact gains a field.

## Acceptance

- [ ] One reader composes what a direction leaves, and the close and the question state it (#20260828052133-read-what-a-direction-leaves-behind.md)
- [ ] An announced successor carries its predecessor's own refs, by explicit slug only (#20260828052133-let-a-direction-name-its-predecessor.md)
- [ ] The last live direction is named to its assignee before it is closed (#20260828052133-say-it-before-the-silence-to-somebody.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
