---
type: Feedback
title: Loop engineering reorganization decided
kind: insight
source: discussion
created_at: 2026-07-28T20:20:17+09:00
author: a@qmu.jp
supersedes: 
---

# Loop engineering reorganization decided

workaholic is reorganizing into a loop-engineering team development engine (decision record: docs/loop-engineering-workflow.md, decided 2026-07-28). Conclusions: feedback becomes the single unified inbound stream of project context (one immutable file per record; concerns merge in as kind: concern; direction lives here, retiring the strategy layer); mission ownership returns to the mission's own assignees; missions are an optional, epic-equivalent grouping of tickets, never a required parent; /drive becomes the sole executor (retiring /monitor, /trip, /carry), autonomously partitioning approved missions and backlog tickets into PR-worthy units coordinated by pushed claim branches, driven by a Drive Every 5 Minutes routine; merge policy is recorded per artifact at creation; Slack (Claude Tag inbound, bot outbound) is the conversation surface while the repository stays the primary source of every decision-bearing artifact.
