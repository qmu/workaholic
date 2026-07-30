---
type: Feedback
title: The mission skill is still 380 lines, well above the guideline it was measured against
kind: concern
source: development
created_at: 2026-07-30T19:07:49+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-mission-skill-is-still-380
owner: 
mission: []
tickets: [20260729121502-shrink-mission-skill-file.md]
origin_pr: 109
origin_pr_url: https://github.com/qmu/workaholic/pull/109
origin_branch: work-20260730-180928
origin_commit: 9910d689
last_seen: 2026-07-30T19:07:49+09:00
---

# The mission skill is still 380 lines, well above the guideline it was measured against

## Description

The ticket deliberately set no hard target, and 380 is a 32% reduction — but it is still more than double the ~50-150 band `CLAUDE.md` states (see [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b) in `plugins/workaholic/skills/mission/SKILL.md`). What remains is content an agent running `/mission` genuinely needs at load time (lifecycle, allowed location, the schema block, the Creation Interrogation, replan, the position report, the ending doctrine, the update seams), so further shrinking means either moving something load-bearing or tightening prose that carries decisions.

## How to Fix

Treat the guideline as measured against *what an agent needs before acting*, and re-derive the band from that rather than shrinking further for its own sake — or accept that a few skills are legitimately above it and say so in `CLAUDE.md`, which currently reads as a flat rule. The two short redefinition records were deliberately left beside the rules they explain, because separating a rule from its *why* costs a reader more than 21 lines.
