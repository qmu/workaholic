---
kind: idea
origin_pr: 32
origin_pr_url: https://github.com/qmu/workaholic/pull/32
origin_branch: drive-20260326-183949
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- The workspace guard uses AskUserQuestion with two options; if the user selects "Ignore and proceed," unrelated changes will persist through the command and may cause conflicts during ship's merge-pr checkout (see [5af3a6e](https://github.com/qmu/workaholic/commit/5af3a6e) in `plugins/core/commands/ship.md`)
