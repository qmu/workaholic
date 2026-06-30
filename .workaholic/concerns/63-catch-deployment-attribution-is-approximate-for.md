---
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
created_at: 2026-07-01T01:12:10+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# `/catch` deployment attribution is approximate for shared branches

## Description

Deployments are attributed by the git author of the ship commit that last touched the story/release-note, joined on branch (see [5a5623c](https://github.com/qmu/workaholic/commit/5a5623c) in `plugins/workaholic/skills/catch/scripts/scan-window.sh`); a branch shipped by someone other than its author attributes to the shipper.

## How to Fix

The report notes this join semantics; deeper attribution would require an author field on stories/release-notes.
