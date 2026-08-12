---
type: Mission
title: Make the propose–implement loop drillable on demand
slug: make-the-propose-implement-loop-drillable-on-demand
status: active
merge_policy: auto
created_at: 2026-08-13T04:04:28+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260812-193807
---

# Make the propose–implement loop drillable on demand

## Goal

The loop is tested only by waiting for its hourly ticks and reading what broke —
measured 2026-08-12, a discovery regression cost a day of ticks before a human
read the logs. The operator needs the whole chain — ask in, `[Propose]` fire,
`[Implement]` fire — exercised on demand, with machine-read verdicts per stage.

## Experience

One command seeds a fresh drill pair — an assigned GitHub issue (the sanctioned
inbox) and a `dev-<repo>` Slack root carrying the issue URL, so both finish lines
thread under it. The operator fires each routine by trigger id; one verify command
per stage prints a pass/fail row per artifact, each failure naming the one file to
read. Slack rows are advisory. A clean pass self-cleans; an abort is recovered by
an idempotent reset touching only drill-owned residue. Re-runnability comes from
minting a fresh issue per run, never from deleting history.

## Acceptance

- [x] Two consecutive drill passes (seed → fire `[Propose]` → verify → fire `[Implement]` → verify) complete with no manual step between seed and the implement verdict, the second run needing nothing beyond the drill's own reset (#20260812190501-add-the-loop-drill-script-seed-status-reset.md)
- [x] `docs/loop-drill-runbook.md` takes an operator from seed to a clean pass without consulting any other document, mapping every named abort reason to one file to read (#20260812190503-write-the-loop-drill-runbook.md)
- [x] The drill scripts' guard tests pass offline in `node scripts/test-workflow-scripts.mjs` (#20260812190502-add-drill-verify-subcommands-for-each-stage.md)

## Changelog

- 2026-08-12 — ticket archived — 20260812190501-add-the-loop-drill-script-seed-status-reset.md
- 2026-08-12 — ticket archived — 20260812190502-add-drill-verify-subcommands-for-each-stage.md
- 2026-08-12 — ticket archived — 20260812190503-write-the-loop-drill-runbook.md
- 2026-08-12 — story — work-20260812-193807.md
