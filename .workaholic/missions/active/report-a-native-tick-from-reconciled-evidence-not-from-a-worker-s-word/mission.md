---
type: Mission
title: Report a native tick from reconciled evidence, not from a worker's word
slug: report-a-native-tick-from-reconciled-evidence-not-from-a-worker-s-word
status: active
merge_policy:
created_at: 2026-09-09T13:00:46+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260909125918-repair-the-native-work-loop-s-control-delivery-and-truthful-reporting.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260909-200531
---

# Report a native tick from reconciled evidence, not from a worker's word

## Goal

A 2026-09-08 native `/work` retrospective: completion reported with zero merges, six queued
tickets and two unreconciled pull requests; runners stopped on `session_type_cannot_merge` while
an authorized squash merge then succeeded; a migration that passed on an empty database failed on
the existing rows and read as healthy. The report relayed each worker's word.

## Experience

The operator reads a tick report they can act on without checking it. A delivery refusal names
which capability refused — no tooling, an API error, or an authorization denial — and an
authorized route that exists is used. A completion claim is checked against merges, claims and the
queue; a failed or pending deployment stays visible.

## Acceptance

- [ ] A delivery refusal names which capability refused, and an authorized route is used. (#20260909130138-name-which-capability-refused-a-delivery-and-use-an-authorized-route.md)
- [ ] A completion claim is reconciled against merge state, claims and the queue before it is made. (#20260909130138-reconcile-a-completion-claim-against-merges-claims-and-the-queue.md)
- [ ] A constraint tightened over persisted data is verified against legacy rows. (#20260909130138-verify-a-constraint-tightening-migration-against-legacy-rows.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
