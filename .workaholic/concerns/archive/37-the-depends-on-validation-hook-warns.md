---
origin_pr: 37
origin_pr_url: https://github.com/qmu/workaholic/pull/37
origin_branch: work-20260408-001129
origin_commit: cc5de17
created_at: 2026-05-19T11:48:42+09:00
last_seen: 2026-05-19T11:48:42+09:00
first_seen: 2026-05-19T11:48:42+09:00
concern_id: the-depends-on-validation-hook-warns
status: resolved
resolved_by_pr: 
resolved_by_commit: 
---
- The `depends_on` validation hook warns but does not block on missing referenced tickets, since during a split operation the dependent ticket may be validated before the prerequisite is written; this means invalid references could persist undetected (see [bf57f48](https://github.com/qmu/workaholic/commit/bf57f48) in `plugins/work/hooks/validate-ticket.sh`)
