---
type: Mission
title: Make the routine create body documented and buildable
slug: make-the-routine-create-body-documented-and-buildable
status: active
merge_policy:
created_at: 2026-08-21T15:02:46+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
assignee:
predicted_hours:
actual_hours:
feedback: [20260821150124-workaholify-cannot-create-a-routine-the-environment-id-and-body-shape-are-undocumented.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make the routine create body documented and buildable

## Goal

`/workaholify` §5 reached an empty account carrying `RemoteTrigger`, found five templates to
create, and created none: the create call needs `job_config.ccr.environment_id`, which nothing
supplies and no document names a source for. `render-routine.sh` declines to emit `job_config`
because the body shape "belongs to the tool's own contract" — but that contract documents
actions, not `job_config`. The shape that worked here on 2026-08-19 was copied off a live
record, so an account with **zero** routines — §5's only real work — fails.

## Scope

`reference/routines.md`, §5, the templates, `render-routine.sh`. Not the transport search.

## Experience

`/workaholify` on an account with no routines creates every template in one pass, with no API
probing to discover the body shape. A template declaring `mcp: []` ends the run with
`mcp_connections: []` on the record. `[Workaholic]` is created pointing at qmu/workaholic
without anyone reading a template's prose. A session that reaches the account but cannot
resolve an environment says so by name, and still renders no setup sheet.

## Acceptance

- [ ] The verified create/update body is recorded field by field; no caller walks 400s for it (#20260821150359-record-the-verified-routine-create-and-update-body.md)
- [ ] One place builds the body; templates carry `sources:` and it is rendered, not prose (#20260821150359-build-the-routine-api-body-in-one-place.md)
- [ ] §5 states the environment rule and names a second refusal beside `no_transport` (#20260821150359-state-the-environment-rule-and-its-named-refusal.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
