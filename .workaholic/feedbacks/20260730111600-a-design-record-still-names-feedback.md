---
type: Feedback
title: A design record still names `/feedback` as the capture command
kind: concern
source: development
created_at: 2026-07-30T11:16:00+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: a-design-record-still-names-feedback
owner: 
mission: []
tickets: []
origin_pr: 103
origin_pr_url: https://github.com/qmu/workaholic/pull/103
origin_branch: work-20260729-193859
origin_commit: 2e7f1b00
last_seen: 2026-07-30T11:16:00+09:00
---

# A design record still names `/feedback` as the capture command

## Description

`docs/loop-engineering-workflow.md:177` still reads "A capture skill/command (working name `/feedback`)". It was accurate when written and is hedged as a working name, but it is now the only place in the tree pointing a reader at a trigger that resolves to Anthropic's built-in — and it sits in the document the tickets treat as the authoritative decision record.

## How to Fix

Update the line to `/fb` with a parenthetical noting the collision, or strike the working name and reference `commands/fb.md`, which now carries the canonical rationale.
