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
concern_id: archive-script-records-the-pre-amend
severity: moderate
status: resolved
resolved_by_pr: 9d4b22c
resolved_by_commit: 
---

# Archive script records the pre-amend commit hash

## Description

`archive.sh` captures `COMMIT_HASH` before it amends the ticket with `commit_hash` and `category`, so the archived ticket can point at the pre-amend commit instead of the final commit (see [aab56a9](https://github.com/qmu/workaholic/commit/aab56a9) in `plugins/workaholic/skills/drive/scripts/archive.sh`).

## How to Fix

Move the final `git rev-parse --short HEAD` until after the amend, then update the printed output and any ticket frontmatter expectations with the post-amend hash.
