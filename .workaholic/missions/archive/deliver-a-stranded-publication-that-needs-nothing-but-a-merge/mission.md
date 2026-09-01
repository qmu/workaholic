---
type: Mission
title: Deliver a stranded publication that needs nothing but a merge
slug: deliver-a-stranded-publication-that-needs-nothing-but-a-merge
status: achieved
merge_policy:
created_at: 2026-09-01T03:24:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901032409-a-clean-stranded-publication-is-delivered-by-nothing.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-034625
---

# Deliver a stranded publication that needs nothing but a merge

## Goal

A publication whose auto-merge lost a race with its own CI reads `clean` and is delivered
by nothing: `settle-stranded-publication.sh` refuses it `not_mechanical:clean`, the claim
keyed retry never sees it, and `/moderate` asks about `content` only. Five of six open
publications sat that way for up to six days, green and unmerged. Give the class an owner.

## Experience

A stranded publication that needs nothing but a merge is merged by the loop, on the tick
that reads it: the gate still runs, the act still re-derives its own class and refuses by
its own word, and a `content` collision still waits on the person it always waited on.
A regression that leaves the class ownerless fails a drill.

## Acceptance

- [x] `settle-stranded-publication.sh` settles a `clean` publication and delivers it, taking
      no catch-up, running the gate first, and staying idempotent and refused by its own word (#20260901032501-settle-a-clean-stranded-publication.md)
- [x] `/implement` acts on every `clean` entry it reads and reports both outcomes per entry,
      with the docs stating which class each act owns (#20260901032502-act-on-every-clean-publication-the-run-reads.md)
- [x] A drill fails when a `clean` publication stops being settled (#20260901032502-drill-the-clean-publication-settlement.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901032501-settle-a-clean-stranded-publication.md
- 2026-09-01 — ticket archived — 20260901032502-act-on-every-clean-publication-the-run-reads.md
- 2026-09-01 — ticket archived — 20260901032502-drill-the-clean-publication-settlement.md
- 2026-09-01 — mission achieved — mission.md
- 2026-09-01 — story opened — work-20260901-034625.md
