---
type: Mission
title: Retire a claim whose work is finished or abandoned
slug: retire-a-claim-whose-work-is-finished-or-abandoned
status: active
merge_policy:
created_at: 2026-09-02T06:28:07+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260902062425-a-closed-pull-request-and-an-abandoned-mission-still-read-as-stuck-work-and-the-tick-asks-a-person-to-do-its-own-job.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Retire a claim whose work is finished or abandoned

## Goal

The operator closed a pull request and abandoned its mission; the tick reported that
branch as stuck work hourly until a person deleted it. Retirement is keyed on the pull
request alone, so a claim whose mission ended has no term at all, and the stuck-work
steps filter only `superseded` and `awaiting_verification`.

## Scope

The retirement candidates and the stuck-work questions. Not conflict resolution and not
the question wording, both planned elsewhere.

## Experience

A claim whose pull request is closed, or whose mission is no longer active, is retired by
the tick — its branch deleted, its claim released — and never appears in a question about
stuck work. What is reported as stuck is only what somebody could still act on.

## Acceptance

- [ ] A claim whose mission is no longer active is its own retirement candidate, proved
      from the tree, and CI deletes its branch. (#20260902062857-name-a-claim-whose-mission-ended-as-a-retirement-candidate.md)
- [ ] A claim whose pull request is closed, or whose mission is not active, is filtered
      out of the stuck-work questions and counted instead. (#20260902062857-filter-a-retired-by-definition-claim-out-of-the-stuck-work-questions.md)
- [ ] Both readings are drilled offline and stated where the claim vocabularies are read. (#20260902062857-drill-the-two-retirement-readings-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
