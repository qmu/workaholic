---
type: Mission
title: Stop two runs from claiming and driving one unit
slug: stop-two-runs-from-claiming-and-driving-one-unit
status: active
merge_policy:
created_at: 2026-08-30T08:20:09+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours: 1.2
feedback: [20260830081659-stop-two-runs-from-claiming-and-driving-one-unit.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260830-094214
---

# Stop two runs from claiming and driving one unit

## Goal

Two runs claimed and drove one unit on 2026-08-30, four seconds apart. `claims.md` says
the protocol settles a race by the push — false for a fresh claim, named from the clock,
so two runners surveying before either pushes contend for nothing. The loser then reads
`report_undelivered`, not `superseded`, and nothing says it was driven twice.

## Scope

`claim.sh`, `create.sh`, `lib/claims.sh`, `claim-merged.sh`, `archive.sh`, the run
report, one `/moderate` question, one drill. Not the verdict vocabulary or `work-*`
naming.

## Experience

A runner that loses a claim race stops within its survey, having written nothing — no
branch, no worktree, no archive, no duplicated implementation. A unit whose content
reached the base through another branch reads `superseded` at either grain, so the loser
is retired by existing machinery rather than left as a person's conflict. When a race
happens, one person is told once, both branches named.

## Acceptance

- [ ] The claim contends for one ref per unit: the first push wins, the second is refused
      by its own word, and the loser holds no branch, worktree or commit. (#20260830082251-make-the-claim-contend-for-one-ref-per-unit.md)
- [x] A unit whose content landed through a racing twin reads `superseded` at the mission
      grain from the tree, so the existing retirement path reaches it. (#20260830082251-answer-superseded-at-the-mission-grain-from-the-tree.md)
- [x] A lost race is named where a person reads it — the run report and one `/moderate`
      question naming both branches — proved by a drill with a breaker row. (#20260830082251-report-a-lost-race-where-a-person-reads-it.md)

## Changelog
- 2026-08-30 — ticket archived — 20260830082251-correct-the-settled-by-the-push-premise.md
- 2026-08-30 — ticket archived — 20260830082251-answer-superseded-at-the-mission-grain-from-the-tree.md
- 2026-08-30 — ticket archived — 20260830082251-re-check-the-claim-before-the-first-archive-write.md
- 2026-08-30 — ticket archived — 20260830082251-reproduce-the-claim-race-offline-in-a-drill.md
- 2026-08-30 — run recorded (+0.9h) — session_01W6TxsNWDVy4A7CZSg3wKqx
- 2026-08-30 — run recorded (+0.3h) — cse_01DzM3RauLKBVSvjwNV1W4zw
- 2026-08-30 — ticket archived — 20260830082251-report-a-lost-race-where-a-person-reads-it.md
