---
type: Feedback
title: the-sh-to-scripts-rename-touches
kind: concern
source: development
created_at: 2026-05-19T11:48:41+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-sh-to-scripts-rename-touches
owner: 
mission: 
tickets: []
origin_pr: 33
origin_pr_url: https://github.com/qmu/workaholic/pull/33
origin_branch: drive-20260329-173608
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:41+09:00
closed: resolved
---

- Add a link checker script that verifies all `${CLAUDE_PLUGIN_ROOT}/../` cross-plugin references resolve to files that actually exist, run as a pre-commit hook or CI step
