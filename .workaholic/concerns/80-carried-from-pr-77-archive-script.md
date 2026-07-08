---
type: Concern
mission: 
tickets: [20260707104117-fix-installed-script-helper-resolution.md, 20260707220735-guard-hook-scripts-executable.md, 20260709023255-catch-scan-mission-join.md, 20260709023256-catch-report-missions-section.md]
origin_pr: 80
origin_pr_url: https://github.com/qmu/workaholic/pull/80
origin_branch: work-20260707-104047
origin_commit: cf6a1d8
created_at: 2026-07-09T03:28:39+09:00
severity: moderate
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #77) Archive script records the pre-amend commit hash

## Description

`archive.sh` records `commit_hash` before any rebase/amend; if the developer later rebases (squash, reorder) the recorded hash goes stale and a report run can show an already-amended commit as newly archived. This branch itself hit it — each archived ticket's frontmatter hash is the pre-amend value, so the story's section 3 links use the real landing hashes from `git log` instead.

## How to Fix

Record the hash post-amend (after any pre-push rebase), or regenerate it at report time by re-running `collect-commits.sh` against the actual landing commit.
