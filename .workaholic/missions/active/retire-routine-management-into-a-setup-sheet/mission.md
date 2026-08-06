---
type: Mission
title: Retire routine management into a setup sheet
slug: retire-routine-management-into-a-setup-sheet
status: active
merge_policy:
created_at: 2026-08-06T14:39:19+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260806143907-routine-setup-is-a-human-act-the-plugin-makes-cheap.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260806-153117
---

# Retire routine management into a setup sheet

## Goal

`/setup-routines` was built as an API management surface — survey the account,
report drift, create and refresh routines behind a digest gate. The half that
decides whether a routine runs at all (its trigger wiring) turned out to be
web-UI-only: unreadable, unwritable and unverifiable from a session, while the
readable half misled twice in one day (a paginated list read as the whole
account; six duplicate records carefully updated while the real, wired routine
ran a stale prompt). The developer's ruling: the management surface does not
hold, and the plugin's one job here is to make the human's UI setup as cheap
as possible.

## Experience

A developer runs `/setup-routines` (or reaches it via `/workaholify`) and gets,
for each template, a copy-paste **setup sheet**: the routine's name, model, the
prompt body verbatim in one block, the trigger's exact UI steps (event and
filters, from a structured declaration in the template), the connectors and the
Slack channel to have ready. They open claude.ai/code/routines beside it, paste
and click, and are done — the plugin never claims to know what the account holds,
and nothing asks them to confirm an API mutation that no longer exists.

## Acceptance

<!-- PROPOSED criteria — replan sharpens them. -->

- [ ] Each routine template declares its trigger as structured data (kind, event,
      filters), and `/setup-routines` renders per-template copy-paste setup
      sheets from it — no `RemoteTrigger` call anywhere in the command. (#20260806144006-render-copy-paste-setup-sheets-from-structured-trigger-declarations.md)
- [ ] The API management machinery (plan/authorize digest gate, compare/list
      drift reporting) is retired with its tests, and every document that
      presented it as the management surface tells the new truth. (#20260806144006-retire-the-routine-api-management-machinery-and-its-tests.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
