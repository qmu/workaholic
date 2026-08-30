---
type: Mission
title: Draft a dateless direction with the operator's one-week default
slug: draft-a-dateless-direction-with-the-operator-s-one-week-default
status: active
merge_policy:
created_at: 2026-08-30T04:19:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260830041720-a-strategy-ask-lacking-only-its-date-dies-quietly-as-a-direction-record.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260830-055318
---

# Draft a dateless direction with the operator's one-week default

## Goal

An ask with an aim and an owner but no date is refused `no_target_date`, its
refusal traced only by a parenthetical addressed to nobody — three announced
directions died there and nobody was asked for the missing part. The operator has
ruled the default: **one week from the ask**.

## Experience

Such an ask reaches a **drafted strategy** at an open pull request, dated a week
out and saying on its face that the date is the default rather than the operator's
word — so their merge is still the authorship and editing the date is the veto. A
date the ask *states* is never overwritten, and one it states unparseably stays
record-only rather than being silently defaulted over.

## Acceptance

- [ ] An ask with an aim and an owner but no date emits a strategy on the
      never-auto-merge path, with `target_date` = the ask's date + 7 days (#20260830042044-draft-a-dateless-direction-on-the-default-instead-of-refusing.md)
- [ ] The default is derived in one place, applies only where the ask stated no
      date, and `no_target_date` narrows to what it still answers (#20260830042044-derive-the-one-week-target-date-default-in-one-place.md)
- [ ] Every surface carrying it — `## Schedule`, the pull-request body, the run
      report — names the date as a default, and the chain is pinned (#20260830042044-say-on-every-surface-that-the-date-is-a-default.md)

## Changelog

- 2026-08-30 — proposed from issue #743
