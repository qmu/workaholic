---
type: Mission
title: Name the session type that cannot merge
slug: name-the-session-type-that-cannot-merge
status: achieved
merge_policy:
created_at: 2026-08-21T15:07:02+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
assignee:
predicted_hours:
actual_hours:
feedback: [20260821150642-auto-merge-cannot-merge-in-a-web-session-while-the-connector-can.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-171036
---

# Name the session type that cannot merge

## Goal

`WORKAHOLIC_AUTO_MERGE=1` merges over REST. Measured 2026-08-20 on an hourly tick, a Claude
Code on the web session gets **403 "Merging pull requests is not permitted for this session
type"** — and 403 is neither the 405 nor the 409 the script names, so it lands in
`merge_failed`, the unknown-failure bucket. Every proposal pull request opened from a remote
session therefore stays open, and the report blames nothing in particular, so a reader looks
for a defect in their own change. The GitHub MCP merge tool merged the same PR with 200
seconds later, which is what makes this a transport question rather than a permissions one.

## Scope

`publish-tree-pr.sh`'s merge-reason ladder, and a ruling on whether an agent-level connector
may be a sanctioned merge seam. Not the scan gates, not `rules/shell.md`'s REST rule.

## Experience

A proposal published from a web session either merges, or names the refusal so plainly that
nobody re-reads their own diff looking for the cause.

## Acceptance

- [x] A session-type refusal has its own `merge_reason`, distinct from `merge_failed` (#20260821150710-name-the-session-type-merge-refusal.md)
- [x] Whether a connector may merge is ruled on in writing, with the reasoning recorded (#20260821150710-rule-on-the-connector-as-a-merge-transport.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-23 — ticket archived — 20260821150710-name-the-session-type-merge-refusal.md
- 2026-08-23 — ticket archived — 20260821150710-rule-on-the-connector-as-a-merge-transport.md
- 2026-08-23 — mission achieved — mission.md
