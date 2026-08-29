---
type: Mission
title: Land the loop's own work when the base moves under it
slug: land-the-loop-s-own-work-when-the-base-moves-under-it
status: achieved
merge_policy:
created_at: 2026-08-29T06:19:41+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260829061651-land-the-loop-s-own-work-when-the-base-moves-under-it.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260829-064113
---

# Land the loop's own work when the base moves under it

## Goal

A claim branch is caught up with `main` once, during the run that drives it, and never
again; `retry-undelivered.sh` re-attempts a merge the transport refused, no act at all for
a moved base. Measured 2026-08-29: 4 of 7 open pull requests conflicting, three green and
undelivered behind 4 missions and 10 tickets.

The mechanical case only, on this identity's own claim: merge the base in (never a rebase,
amend or force-push), regenerate, validate, push, deliver. A `content` conflict, a
colleague's claim and a scan-held pull request are refused.

## Experience

A pull request the loop opened and could not merge is brought back onto the base by the
loop itself and re-delivered in the same turn. A conflict the loop must not resolve is
refused by name, leaves the branch byte-identical, and reaches its claim holder as a
question: nobody looked, or the loop looked and only you decide.

## Acceptance

- [x] Mergeability reads `clean|mechanical|content|unanswerable`, and a `mechanical` branch is caught up, validated, pushed and delivered in one turn. (#20260829062039-read-whether-a-claim-branch-still-merges.md)
- [x] Every refusal is named and writes nothing: `content`, foreign claim, scan-held, dirty tree, non-`work-*` (#20260829062039-catch-a-claim-branch-up-with-the-base.md)
- [x] A refused `content` conflict reaches its holder as its own question, apart from one untried. (#20260829062039-ask-about-the-conflict-the-loop-must-not-resolve.md)

## Changelog
- 2026-08-29 — ticket archived — 20260829062039-reproduce-the-base-drift-that-strands-a-unit.md
- 2026-08-29 — ticket archived — 20260829062039-read-whether-a-claim-branch-still-merges.md
- 2026-08-29 — ticket archived — 20260829062039-catch-a-claim-branch-up-with-the-base.md
- 2026-08-29 — ticket archived — 20260829062039-retry-the-delivery-of-a-caught-up-unit.md
- 2026-08-29 — ticket archived — 20260829062039-ask-about-the-conflict-the-loop-must-not-resolve.md
- 2026-08-29 — ticket archived — 20260829062039-name-the-catch-up-outcome-in-the-run-report.md
- 2026-08-29 — ticket archived — 20260829062039-drill-the-catch-up-with-no-network.md
- 2026-08-29 — ticket archived — 20260829062039-state-the-catch-up-and-its-refusals.md
- 2026-08-29 — mission achieved — mission.md
