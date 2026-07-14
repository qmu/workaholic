---
type: Concern
concern_id: list-active-deferred-concerns-sh-can
mission: 
tickets: [20260713144839-worktree-copies-root-env.md, 20260713203444-concern-identity-update-in-place.md, 20260713203445-report-concern-triage-and-compound-merge.md]
origin_pr: 83
origin_pr_url: https://github.com/qmu/workaholic/pull/83
origin_branch: work-20260713-144839
origin_commit: fbceaaa
created_at: 2026-07-13T23:39:50+09:00
first_seen: 2026-07-13T23:39:50+09:00
last_seen: 2026-07-13T23:39:50+09:00
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# list-active-deferred-concerns.sh can emit transiently-invalid JSON during the first large migration

## Description

On the very first run that collapses a large legacy backlog, `list-active` emitted one malformed JSON record (an unescaped control character) while the migration was mutating ~200 files in the same call; subsequent runs were stable and valid (see [da318d7](https://github.com/qmu/workaholic/commit/da318d7) in `plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh`). The root cause was not fully isolated. Because the deferred-concern judge parses this output, a first-collapse run in a fresh repo could feed the judge invalid JSON.

## How to Fix

Build the entire JSON array in a single Python pass (as `migrate`/`extract` already do) instead of shell string-assembly with per-field `escape_json`, or validate the assembled output and retry once; add a hermetic test that runs `list-active` on a large unmigrated fixture and asserts valid JSON.
