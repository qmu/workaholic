---
type: Mission
title: Make a rename a registry entry, not a sweep
slug: make-a-rename-a-registry-entry-not-a-sweep
status: active
merge_policy: auto
created_at: 2026-08-21T03:27:49+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours: 0.75
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260821-035855
---

# Make a rename a registry entry, not a sweep

## Goal

Two old names still stand. `housekeep` survives only as the directory
`.workaholic/housekeeping/` — routine, command and skill all became `moderate`
on 2026-08-19. And `/report` writes a **story**: artifact, area and every calling
seam are all story; only the command is not.

Renaming is not the point. Six things were renamed here in eight days, each
costing a manual sweep plus a migration note somebody had to remember; the next
should cost one table row. Out of scope: any other rename, and `.workaholic/`
history.

## Experience

A rename is declared **once**, as a row in a table the plugin ships. Three things
follow with nobody sweeping:

- `layout-doctor.sh` classifies the old name where it finds it — a directory as
  `renamed-area`, a token as `renamed-name` — naming what it became and when.
- `/workaholify` **applies** the mechanical half (the `git mv` of a
  `.workaholic/` area and the machine-read references inside it) and **proposes**
  the rest as a printed bulk-conversion command the operator runs or declines.
  Nothing outside the artifact tree is rewritten unasked.
- The two renames in flight are the table's first rows and its proof.

## Acceptance

- [x] One table row drives it all: the doctor names the old directory or token, `/workaholify` applies the `.workaholic/` half and prints the conversion for the rest, nothing else is rewritten unasked (#20260820182800-add-the-rename-registry-and-its-convergence-seam.md)
- [x] `.workaholic/housekeeping/` is `moderations/`, and `housekeep` is absent from the live tree (#20260820182801-rename-the-housekeeping-area-to-moderations.md)
- [x] `/story` writes the story and opens the PR as `workaholic:story`; `/report` still runs it behind a deprecation notice (#20260820182802-rename-report-to-story-and-deprecate-report.md)

## Changelog

- 2026-08-20 — mission created — mission.md
- 2026-08-20 — predicted_hours 0.75 stamped from 24 archived missions (0.25 h/item)
- 2026-08-20 — ticket added — 20260820182800-add-the-rename-registry-and-its-convergence-seam.md
- 2026-08-20 — ticket added — 20260820182801-rename-the-housekeeping-area-to-moderations.md
- 2026-08-20 — ticket added — 20260820182802-rename-report-to-story-and-deprecate-report.md
- 2026-08-21 — ticket archived — 20260820182800-add-the-rename-registry-and-its-convergence-seam.md
- 2026-08-21 — ticket archived — 20260820182801-rename-the-housekeeping-area-to-moderations.md
- 2026-08-21 — ticket archived — 20260820182802-rename-report-to-story-and-deprecate-report.md
- 2026-08-20 — story reported — work-20260821-035855.md
