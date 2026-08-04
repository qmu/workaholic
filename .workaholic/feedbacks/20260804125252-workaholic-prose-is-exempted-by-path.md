---
type: Feedback
title: `.workaholic/` prose is exempted by path, not by nature
kind: concern
source: development
created_at: 2026-08-04T12:52:52+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: workaholic-prose-is-exempted-by-path
owner: 
mission: make-the-per-commit-changed-lines-ceiling-a-rule-that-holds
tickets: [20260801185101-decide-what-too-large-commit-counts.md, 20260801185102-implement-the-chosen-commit-size-semantics.md]
origin_pr: 167
origin_pr_url: https://github.com/qmu/workaholic/pull/167
origin_branch: work-20260801-210440
origin_commit: 287bc95c
last_seen: 2026-08-04T12:52:52+09:00
---

# `.workaholic/` prose is exempted by path, not by nature

## Description

The exclusion is a path test, so anything placed under `.workaholic/` is exempt from the commit ceiling regardless of what it is. That is currently exactly right — the tree is a closed, registered set of artifact types — but it couples the gate to the layout rather than to the content's kind (`plugins/workaholic/skills/release-scan/scripts/lib/commit-size.sh`).

## How to Fix

No action while the layout stays closed and registered. If executable content ever lands under `.workaholic/`, the test needs to narrow to the artifact directories rather than the tree root.
