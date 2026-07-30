---
type: Feedback
title: An externally-blocked ticket is re-picked on every drive tick
kind: concern
source: development
created_at: 2026-07-30T20:46:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: an-externally-blocked-ticket-is-re
owner: 
mission: []
tickets: []
origin_pr: 116
origin_pr_url: https://github.com/qmu/workaholic/pull/116
origin_branch: work-20260730-202601
origin_commit: 0722f374
last_seen: 2026-07-30T20:46:10+09:00
---

# An externally-blocked ticket is re-picked on every drive tick

## Description

This ticket is the only item in the backlog, and it cannot be finished from inside this repository. Every `/drive` tick therefore surveys it, claims it, and spends a claim branch discovering the same external blocker (see [e781f825](https://github.com/qmu/workaholic/commit/e781f825) in `.workaholic/tickets/todo/a-qmu-jp/20260724094304-containerize-long-running-servers-policy.md`). The claim protocol contains the waste — a held claim keeps the next tick from re-picking it — but only until the claim is released or goes stale, at which point the cycle resumes.

## How to Fix

The icebox is exactly this case's mechanism, and `/drive` is forbidden from using it in either direction by design, so the move is the developer's: either publish the canonical article, or ice the ticket until it is published. If externally-blocked tickets become common, the durable fix is a first-class blocked state the survey can subtract, rather than leaning on claim staleness.
