---
type: Mission
title: Reduce loop cost and adapt observation cadence
slug: reduce-loop-cost-and-adapt-observation-cadence
status: achieved
merge_policy: review
created_at: 2026-09-08T09:55:05+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Reduce loop cost and adapt observation cadence

## Goal

Make the shared development loop cheaper to understand and run. The first observed Codex tick
consumed about one quarter of its context window after the redesign, while canonical shell and
instruction volume also grew. Reduce those costs before extending the loop's observation cadence.

## Experience

A developer can run the same loop in Claude Code or Codex with a smaller first-tick context and
less canonical machinery. When people are talking in Slack, the loop observes frequently enough
to reply promptly; after sustained silence, including overnight, it progressively checks less
often and becomes responsive again as soon as activity is observed.

## Acceptance

- [x] The selected first-tick instructions and canonical implementation are smaller than the current main baseline without losing the loop's observable contracts. (#20260908095512-reduce-first-tick-context-and-canonical-volume.md)
- [x] Claude Code and Codex share an activity-sensitive observation plan for Slack and assigned feedback issues that shortens after activity and backs off gradually during silence within declared bounds. (#20260908095513-adapt-slack-observation-cadence.md)

## Changelog

- 2026-09-08 — mission created from issue #1084 and the developer's dynamic-observation instruction
- 2026-09-08 — ticket archived — 20260908095512-reduce-first-tick-context-and-canonical-volume.md
- 2026-09-08 — ticket archived — 20260908095513-adapt-slack-observation-cadence.md
- 2026-09-08 — mission achieved — mission.md
- 2026-09-08 — story reported — work-20260908-095427.md
