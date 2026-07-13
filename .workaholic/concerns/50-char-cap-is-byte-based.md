---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-29T13:18:46+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: 50-char-cap-is-byte-based
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# 50-char cap is byte-based outside a UTF-8 locale

## Description

The subject-length check uses `wc -m`, which counts characters only under a UTF-8 locale and bytes under a C/POSIX locale (see [24a3096](https://github.com/qmu/workaholic/commit/24a3096) in `plugins/workaholic/hooks/lib/check-subject.sh`). Japanese subjects therefore enforce a character-accurate 50-char cap only when the runtime locale is UTF-8; in CI's default locale the cap is effectively byte-based and multibyte subjects can false-trip.

## How to Fix

Pin a UTF-8 locale (e.g. `LC_ALL=C.UTF-8`) wherever the gate/hook runs, or switch to a locale-independent character count if byte-vs-char accuracy on Japanese subjects becomes load-bearing.
