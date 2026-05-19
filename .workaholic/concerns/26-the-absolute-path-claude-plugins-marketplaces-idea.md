---
kind: idea
origin_pr: 26
origin_pr_url: https://github.com/qmu/workaholic/pull/26
origin_branch: drive-20260213-131416
origin_commit: cc5de17
created_at: 2026-05-19T11:48:40+09:00
status: active
resolved_by_pr:
resolved_by_commit:
paired_slug:
housekeeping_ticket_emitted: false
---

- The absolute path `~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/` is tied to the specific marketplace installation path; if the plugin installation mechanism changes, all 39+ files will need updating again (see [f494b8e](https://github.com/qmu/workaholic/commit/f494b8e) in `plugins/core/skills/`)
