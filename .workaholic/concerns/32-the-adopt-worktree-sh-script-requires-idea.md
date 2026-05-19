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

- The `adopt-worktree.sh` script requires a clean working tree before switching branches; uncommitted changes will cause an abort rather than automatic stashing (see [0f7bf97](https://github.com/qmu/workaholic/commit/0f7bf97) in `plugins/core/skills/branching/sh/adopt-worktree.sh`)
