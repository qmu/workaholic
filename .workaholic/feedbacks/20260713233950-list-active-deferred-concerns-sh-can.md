---
type: Feedback
title: list-active-deferred-concerns.sh can emit transiently-invalid JSON during the first large migration
kind: concern
source: development
created_at: 2026-07-13T23:39:50+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: list-active-deferred-concerns-sh-can
owner: 
mission: 
tickets: [20260713144839-worktree-copies-root-env.md, 20260713203444-concern-identity-update-in-place.md, 20260713203445-report-concern-triage-and-compound-merge.md]
origin_pr: 83
origin_pr_url: https://github.com/qmu/workaholic/pull/83
origin_branch: work-20260713-144839
origin_commit: fbceaaa
last_seen: 2026-07-16T12:06:03+09:00
closed: accepted
---

# list-active-deferred-concerns.sh can emit transiently-invalid JSON during the first large migration

## Description

The local first-collapse trigger is spent (the migration landed in `f8203d0e`; the script emits valid JSON today), but the structural cause is unfixed: per-field shell string-assembly with an unescaped `origin_pr` interpolation, and it ships to consumer repos via `outputs/workflows/`, where a first collapse re-enters the same path.

## How to Fix

Build the array in a single Python pass; add a hermetic test over a large unmigrated fixture.
