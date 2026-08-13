---
type: Mission
title: Refresh the outdated documentation to match current behavior
slug: refresh-the-outdated-documentation-to-match-current-behavior
status: active
merge_policy:
created_at: 2026-08-13T07:25:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260813072519-update-the-outdated-readme-and-documentation-to-match-current-behavior.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260813-073630
---

# Refresh the outdated documentation to match current behavior

## Goal

Bring the documentation onto the shipped behavior. The root `README.md` still has
`/propose` running "on the reported ask rather than on a clock", the human merge as
the proposal's approval seam, and `/setup-routines` "managing nothing"; the `docs/`
runbooks keep that retired contract. `CLAUDE.md` is the reference, not a subject.

## Scope

`README.md`, `docs/*.md`, `.workaholic/README.md`, `plugins/workaholic/rules/*.md`.
Prose only: no behavior change, no new drift-prevention mechanism.

## Experience

A reader who learns the loop from the documents and then watches a routine tick sees
the same thing happen: the hourly `[Propose]` discovering its own asks, its pull
request merging on opening, quality gated at the `release/*` window, and
`/setup-routines` attempting configuration rather than printing sheets.

## Acceptance

<!-- PROPOSED sketch, interrogated to drive-ready by whoever picks this up. -->

- [x] The root `README.md` states nothing the shipped code contradicts (#20260813072628-correct-the-outdated-statements-in-the-root-readme.md)
- [x] The `docs/` runbooks describe the loops as they now run, with no retired contract left standing (#20260813072628-bring-the-docs-runbooks-in-line-with-the-shipped-loops.md)
- [x] `.workaholic/README.md` and `rules/*.md` name the current writers, layout and gates (#20260813072628-update-the-artifact-hub-and-rules-docs-to-current-behavior.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-13 — ticket archived — 20260813072628-correct-the-outdated-statements-in-the-root-readme.md
- 2026-08-13 — ticket archived — 20260813072628-bring-the-docs-runbooks-in-line-with-the-shipped-loops.md
- 2026-08-13 — ticket archived — 20260813072628-update-the-artifact-hub-and-rules-docs-to-current-behavior.md
- 2026-08-13 — Story written — work-20260813-073630.md
