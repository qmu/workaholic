---
type: Feedback
title: the-standards-plugin-extraction-required-updating
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-standards-plugin-extraction-required-updating
owner: 
mission: 
tickets: []
origin_pr: 32
origin_pr_url: https://github.com/qmu/workaholic/pull/32
origin_branch: drive-20260326-183949
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
resolved_by_pr: 36b0835
---

- The standards plugin extraction required updating both frontmatter skill preloads (using `standards:skill-name` syntax) and inline bash paths (using `/../standards/` directory traversal); missing even one reference causes a runtime resolution failure (see [2f0f504](https://github.com/qmu/workaholic/commit/2f0f504) in `plugins/drivin/commands/scan.md`)
