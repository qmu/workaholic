---
type: Feedback
title: A blocked ticket with no owner outside this repository re-costs every drive
kind: concern
source: development
created_at: 2026-08-01T06:06:41+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: a-blocked-ticket-with-no-owner
owner: 
mission: 
tickets: []
origin_pr: 152
origin_pr_url: https://github.com/qmu/workaholic/pull/152
origin_branch: work-20260801-051756
origin_commit: e8fedf7f
last_seen: 2026-08-01T06:06:41+09:00
---

# A blocked ticket with no owner outside this repository re-costs every drive

## Description

The ticket is unimplementable here and stays in the queue, so every `/drive` that surveys this backlog picks it up, re-runs the checks, and records the same answer. Three commands is cheap, but the pattern has no termination condition and no named owner for the external action (`.workaholic/tickets/todo/a-qmu-jp/20260724094304-containerize-long-running-servers-policy.md`).

## How to Fix

Either name the person responsible for publishing the qmu.co.jp article on the ticket, or move it to the developer-curated icebox until the article exists — the icebox is exactly the place for work the project has decided to defer, and promotion back is a developer act.
