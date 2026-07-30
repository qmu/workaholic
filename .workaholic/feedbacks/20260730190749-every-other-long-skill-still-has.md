---
type: Feedback
title: Every other long skill still has the old shape, and nothing points them at the new one
kind: concern
source: development
created_at: 2026-07-30T19:07:49+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: every-other-long-skill-still-has
owner: 
mission: []
tickets: [20260729121502-shrink-mission-skill-file.md]
origin_pr: 109
origin_pr_url: https://github.com/qmu/workaholic/pull/109
origin_branch: work-20260730-180928
origin_commit: 9910d689
last_seen: 2026-07-30T19:07:49+09:00
---

# Every other long skill still has the old shape, and nothing points them at the new one

## Description

The `reference/` convention now exists and is documented in `CLAUDE.md`, but `mission` is its only user (see [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b) in `CLAUDE.md`). The other two skills the originating issue measured as longest were not touched, and nothing surfaces a skill that has drifted past the guideline — so the next one grows to 562 lines before anyone notices, exactly as this one did.

## How to Fix

Add a line count to whatever already walks the skills (the `Validate Plugins` workflow is the natural host) reporting any `SKILL.md` past a stated threshold as an advisory, not a failure — the same read-only, report-don't-block shape `layout-doctor.sh` uses for the `.workaholic/` tree.
