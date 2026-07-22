---
type: Concern
concern_id: sibling-pr-detection-depends-on-the
mission: []
owner: 
tickets: [20260722200001-fetch-origin-before-resolving-mission-worktree-base.md]
origin_pr: 95
origin_pr_url: https://github.com/qmu/workaholic/pull/95
origin_branch: work-20260723-000846
origin_commit: 2d6215be
created_at: 2026-07-23T02:27:01+09:00
first_seen: 2026-07-23T02:27:01+09:00
last_seen: 2026-07-23T02:27:01+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# Sibling-PR detection depends on the mission slug appearing in a PR title or body

## Description

`list-related-prs.sh` surfaces open PRs whose title or body contains the mission slug (see [dd5335a1](https://github.com/qmu/workaholic/commit/dd5335a1) in `plugins/workaholic/skills/mission/scripts/list-related-prs.sh`), but a PR that implements the mission without naming the slug is not surfaced — and `available: false` (no `gh`/auth/remote) is *unknown*, not *no siblings*. Duplicate effort could still be discovered only after both merge.

## How to Fix

Cross-reference the mission's ticket filenames (from each PR's story `tickets:` relation) in addition to slug-name matching, and treat `available: false` as an explicit "check did not run" signal in the replan prompt.
