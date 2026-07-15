---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-07-15T20:55:56+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: 50-char-cap-is-byte-based
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# 50-char cap is byte-based outside a UTF-8 locale

## Description

The subject-length check uses `wc -m`, which counts characters only under a UTF-8 locale and bytes under C/POSIX (see [24a3096](https://github.com/qmu/workaholic/commit/24a3096) in `plugins/workaholic/hooks/lib/check-subject.sh`). A Japanese subject can false-trip at up to 3x its true length.

## How to Fix

Pin `LC_ALL=C.UTF-8` wherever the gate runs, or switch to a locale-independent character count.

