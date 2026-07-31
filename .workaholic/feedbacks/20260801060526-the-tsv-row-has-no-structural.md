---
type: Feedback
title: The TSV row has no structural guard against a future empty field
kind: concern
source: development
created_at: 2026-08-01T06:05:26+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-tsv-row-has-no-structural
owner: 
mission: 
tickets: [20260801031302-announce-a-claim-the-moment-it-is-pushed.md, 20260801031301-resume-a-claimed-but-unfinished-unit.md, 20260801031304-handoff-is-a-first-class-terminal-state.md]
origin_pr: 151
origin_pr_url: https://github.com/qmu/workaholic/pull/151
origin_branch: work-20260801-051742
origin_commit: 6c625c7b
last_seen: 2026-08-01T06:05:26+09:00
---

# The TSV row has no structural guard against a future empty field

## Description

A tab is an IFS whitespace character, so `read` collapses runs of tabs; an empty middle field vanishes and shifts every later field. This bit once already (an empty `resume_reason` handed `plan-units.sh` the artifact list in the reason slot and an empty artifact list) and the rule is now prose in `lib/claims.sh`, not a check (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

Add a hermetic assertion that every emitted row has exactly the expected field count with no empty field except the last, so a future field addition fails loudly instead of silently mis-parsing.
