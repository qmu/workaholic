---
type: Mission
title: Recover the Codex loop from a retired plugin path and refuse a false healthy status
slug: recover-the-codex-loop-from-a-retired-plugin-path-and-refuse-a-false-healthy-status
status: achieved
merge_policy:
created_at: 2026-09-07T08:26:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.6
feedback: [20260907005942-recover-the-codex-loop-after-plugin-cache-replacement-and-reject-false-healthy-status.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260907-091552
---

# Recover the Codex loop from a retired plugin path and refuse a false healthy status

## Goal

The operator's ask (#1052). On 2026-09-06 a live Codex supervisor launched from cache 1.0.316
kept handing that version's `SKILL.md` to every tick after 1.0.323 replaced it. A tick said
outright that nothing ran and no worker was dispatched, and the run still recorded
`outcome: ready`; `--status` called the process holding the lock `never_started`.

## Experience

The loop notices the tree it was launched from is gone and says so at the tick that finds it,
rather than running on against deleted files. A tick that executed nothing never records a
healthy outcome or transport. `--status` and a start tell apart what a pid and a lock cannot:
a live supervisor, a succeeded tick, an unwritten record.

## Acceptance

- [x] A supervisor whose launch path is retired mid-run stops running against it. (#20260907082737-stop-the-codex-supervisor-running-against-a-retired-plugin-path.md)
- [x] Nothing records a healthy outcome or transport for a tick that did not execute. (#20260907082737-refuse-a-healthy-outcome-for-a-tick-that-executed-nothing.md)
- [x] `--status` and start tell those three apart; a live pid holding the lock is never
      `never_started`. (#20260907082737-tell-a-live-supervisor-from-a-succeeded-tick-and-an-unwritten-record.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-07 — ticket archived — 20260907082737-refuse-a-healthy-outcome-for-a-tick-that-executed-nothing.md
- 2026-09-07 — ticket archived — 20260907082737-tell-a-live-supervisor-from-a-succeeded-tick-and-an-unwritten-record.md
- 2026-09-07 — run recorded (+1.6h) — implement-20260907-091552
- 2026-09-07 — ticket archived — 20260907082737-stop-the-codex-supervisor-running-against-a-retired-plugin-path.md
- 2026-09-07 — mission achieved — mission.md
