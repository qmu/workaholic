---
type: Feedback
title: ticket-frontmatter-commit-hash-values-across
kind: concern
source: development
created_at: 2026-05-19T11:48:42+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: ticket-frontmatter-commit-hash-values-across
owner: 
mission: 
tickets: []
origin_pr: 39
origin_pr_url: https://github.com/qmu/workaholic/pull/39
origin_branch: work-20260417-092936
origin_commit: cc5de17
last_seen: 2026-05-19T11:48:42+09:00
closed: resolved
---

- Ticket frontmatter `commit_hash` values across this branch do not match the live branch hashes because of intermediate rebasing/squashing; downstream tooling that joins ticket-frontmatter hashes to git-log entries would need to fall back to subject matching (see ticket files in `.workaholic/tickets/archive/work-20260417-092936/`)
