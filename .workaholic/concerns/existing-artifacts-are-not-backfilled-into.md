---
type: Concern
mission: 
tickets: [20260706182653-push-deferred-concerns-in-ship.md, 20260706203044-mission-artifact-type-and-command.md, 20260706203045-mission-frontmatter-linkage.md, 20260706203046-mission-progress-and-changelog-automation.md, 20260707023034-fix-codex-hooks-json-parse-error.md]
origin_pr: 77
origin_pr_url: https://github.com/qmu/workaholic/pull/77
origin_branch: work-20260706-182705
origin_commit: 1f2d43e
created_at: 2026-07-07T04:09:44+09:00
last_seen: 2026-07-09T03:28:39+09:00
first_seen: 2026-07-07T04:09:44+09:00
concern_id: existing-artifacts-are-not-backfilled-into
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Existing artifacts are not backfilled into missions

## Description

Mission relations are emitted forward-only; existing tickets, stories, and concerns do not get a mission relation unless future work edits them (see [ce2f436](https://github.com/qmu/workaholic/commit/ce2f436) in `plugins/workaholic/skills/report/SKILL.md`).

## How to Fix

Leave historical artifacts unchanged unless a mission needs backfill, then write a targeted migration ticket that sets `mission:` and `tickets:` relations for a named mission from verifiable evidence.
