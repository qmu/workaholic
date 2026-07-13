---
origin_pr: 69
origin_pr_url: https://github.com/qmu/workaholic/pull/69
origin_branch: work-20260701-171611
origin_commit: e3c3a4b
created_at: 2026-07-01T21:16:06+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-07-01T21:16:06+09:00
concern_id: resumption-tickets-must-list-remaining-work
severity: moderate
status: superseded
resolved_by_pr: 
resolved_by_commit: 
superseded_by: resumption-tickets-must-list-remaining-only
---

# (carried from PR #67) Resumption tickets must list remaining work only

## Description

`/carry` resumption tickets must list only remaining work, but nothing enforces the scoping, risking re-listing completed work (deferred concern `.workaholic/concerns/67-resumption-tickets-must-list-remaining-only.md`).

## How to Fix

Add a scoping check or template that excludes already-done items from the resumption ticket.
