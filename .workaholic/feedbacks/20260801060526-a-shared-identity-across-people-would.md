---
type: Feedback
title: A shared identity across people would let one runner take another's claims
kind: concern
source: development
created_at: 2026-08-01T06:05:26+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-shared-identity-across-people-would
owner: 
mission: 
tickets: [20260801031302-announce-a-claim-the-moment-it-is-pushed.md, 20260801031301-resume-a-claimed-but-unfinished-unit.md, 20260801031304-handoff-is-a-first-class-terminal-state.md]
origin_pr: 151
origin_pr_url: https://github.com/qmu/workaholic/pull/151
origin_branch: work-20260801-051742
origin_commit: 6c625c7b
last_seen: 2026-08-01T06:05:26+09:00
---

# A shared identity across people would let one runner take another's claims

## Description

Resumption is scoped to the claim commit's author matching `git config user.email`. That is the intended reading of "the runner is `a@qmu.jp`" — a developer's own runner inherits their claims — but it means configuring one identity across two *people* silently grants each the other's in-flight work (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

Stated in `drive/SKILL.md`'s *Claims* section as a warning. If shared runners ever become real, the claim would need an explicit owner field rather than inferring it from the commit author.
