---
type: Concern
concern_id: the-identity-migration-under-collapses-title
mission: 
tickets: [20260713144839-worktree-copies-root-env.md, 20260713203444-concern-identity-update-in-place.md, 20260713203445-report-concern-triage-and-compound-merge.md]
origin_pr: 83
origin_pr_url: https://github.com/qmu/workaholic/pull/83
origin_branch: work-20260713-144839
origin_commit: fbceaaa
created_at: 2026-07-13T23:39:50+09:00
first_seen: 2026-07-13T23:39:50+09:00
last_seen: 2026-07-13T23:39:50+09:00
severity: low
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: By design, as the concern's own Description states ('semantic dedup is the triage's job'), and that triage now exists as the sanctioned handler: report/SKILL.md Phase 1b with merge-concerns.sh. Fuzzy pre-clustering remains optional polish, not a defect.
closed_at: 2026-07-15T19:50:28+09:00
reopened_note: 'The premise of the 2026-07-15 acceptance was unsound WHEN MADE: the sanctioned handler it points at was not round-trip safe. merge-concerns.sh minted a hand-invented id, so the next ship cloned the compound instead of updating it in place - the triage door re-introduced the very carried-from chain the identity collapse killed. The acceptance stands, but only because 2026-07-16 made the premise true: the compound id is now derived from the title by the same slugify() the extractor uses, and a round-trip regression test pins created:0/updated:1. Recorded rather than left standing, per the driving ticket step 5.'
reopened_at: 2026-07-16T01:49:00+09:00
---

# The identity migration under-collapses title-drift near-duplicates

## Description

`concern_id` is the slug of the title; when the same concern was re-worded across PRs (e.g. "50-char cap" vs "50-char subject cap"), the migration leaves two active files with different ids, so the mechanical collapse got 65→38 and the remaining ~6 duplicates needed the human triage merge (see [b33d64f](https://github.com/qmu/workaholic/commit/b33d64f) in `plugins/workaholic/skills/report/scripts/migrate-concern-identity.sh`).

## How to Fix

This is by design (semantic dedup is the triage's job), but a fuzzy-match hint (shared significant-word overlap) could pre-cluster likely duplicates and offer them as merge candidates in Phase 1b.
