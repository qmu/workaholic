---
type: Mission
title: Compose the squash body so a unit's housekeeping stays off the trunk
slug: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
status: active
merge_policy:
created_at: 2026-09-03T10:41:45+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260903103841-compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260903-113842
---

# Compose the squash body so a unit's housekeeping stays off the trunk

## Goal

Every merge this loop makes is squash-merged and no call site passes a `commit_message`, so the
forge concatenates the branch's own commits into the trunk's record. Measured: 190 commits on `main`
carrying `Refresh heartbeat`, and one squash body 267 lines long. The composed statement already
exists — the branch story — and nothing reads it.

## Experience

What enters the trunk is composed, not concatenated: every merge writes a squash body derived
from the unit's own story, a run's housekeeping commits are marked so the composer drops them by
rule rather than by a title pattern, and a call site that spells the body itself fails the suite.
History already on the trunk is left alone.

## Acceptance

- [ ] Every merge call site reads one composer for its squash title and body, and a merge made by
      the loop never carries the forge's concatenation. (#20260903104222-compose-the-squash-body-at-the-agent-level-merges.md)
- [ ] A run's housekeeping commits carry a machine-readable marker, and the composer excludes them
      by that marker rather than by a title pattern. (#20260903104222-mark-a-run-s-housekeeping-commits-as-housekeeping.md)
- [ ] The suite fails a call site that spells the body itself or omits the composer. (#20260903104222-fail-a-merge-call-site-that-spells-its-own-body.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
