---
origin_pr: 10
origin_pr_url: https://github.com/qmu/workaholic/pull/10
origin_branch: feat-20260128-001720
origin_commit: cc5de17
created_at: 2026-05-19T11:48:41+09:00
status: resolved
resolved_by_pr: d4352d5
resolved_by_commit: 
---
- The architecture policy documents that skills should not invoke subagents, but this branch leaves the performance-analyst invocation instruction in write-story skill. A follow-up ticket should address this by moving the invocation to the orchestrator level.
