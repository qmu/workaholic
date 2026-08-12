---
type: Mission
title: Configure routines automatically via RemoteTrigger
slug: configure-routines-automatically-via-remotetrigger
status: achieved
merge_policy:
created_at: 2026-08-10T13:05:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 0.65
feedback: [.workaholic/feedbacks/20260810214929-make-setup-routines-and-workaholify-configure-routines-automatically-via-remotetrigger.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260810-210319
---

# Configure routines automatically via RemoteTrigger

## Goal

`/setup-routines`/`/workaholify` only render setup sheets — the "manages nothing" ruling rested on no `RemoteTrigger`-family tool being exposed. Stale for an interactive session: a live 2026-08-10 check listed this repo's routines via `RemoteTrigger`, found both had an empty (unscheduled) `cron_expression`, and wrote working hourly schedules onto both. Read/diff/apply directly where the tool is exposed, keep the sheet as fallback, and stop generating the unrealizable `0,30 * * * *` (min interval is 1h) and bare `:00` (server-jittered).

## Experience

A session with a `RemoteTrigger`-family tool lists the account's routines, diffs each against its template (name/prompt/model/schedule/connectors), and applies the wiring — reporting what changed. Without the tool, the sheet fallback is unchanged. Either way the templates only declare a schedule the API can realize.

## Acceptance

- [x] `/setup-routines` detects `RemoteTrigger` availability and, when available, lists/diffs/applies routine wiring directly; falls back to today's sheet-only behavior otherwise. (#20260810130703-apply-routine-wiring-directly-via-remotetrigger-in-setup-routines.md)
- [x] The `[Propose]`/`[Implement]` templates declare a realizable hourly `cron_expression` with a non-zero minute (never `0,30 * * * *`, never bare `:00`), docs updated to match. (#20260810130657-fix-the-routine-templates-unrealizable-30-minute-schedule.md)
- [x] `workaholic:workaholify` and `CLAUDE.md`'s `/setup-routines` row restate "manages nothing" as session-class-dependent, not unconditional. (#20260810130705-restate-the-manages-nothing-ruling-as-session-class-dependent.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-10 — ticket archived — 20260810130657-fix-the-routine-templates-unrealizable-30-minute-schedule.md
- 2026-08-10 — ticket archived — 20260810130703-apply-routine-wiring-directly-via-remotetrigger-in-setup-routines.md
- 2026-08-10 — ticket archived — 20260810130705-restate-the-manages-nothing-ruling-as-session-class-dependent.md
- 2026-08-10 — run recorded (+0.5h) — implement-20260810-202951
- 2026-08-10 — ticket archived — 20260810203351-fix-acceptance-link-marker-mismatch-full-path-vs-basename.md
- 2026-08-10 — run recorded (+0.15h) — implement-20260810-210319
- 2026-08-12 — mission achieved — mission.md
