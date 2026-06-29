---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# (carried from PR #59) 50-char subject cap is byte-based outside a UTF-8 locale

## Description

The subject-length check uses `wc -m`, which counts characters only under a UTF-8 locale and bytes under C/POSIX (`plugins/workaholic/hooks/lib/check-subject.sh`); Japanese subjects enforce a character-accurate cap only when the runtime locale is UTF-8.

## How to Fix

Pin a UTF-8 locale (e.g. `LC_ALL=C.UTF-8`) where the gate runs, or switch to a locale-independent character count.
