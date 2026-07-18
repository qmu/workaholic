---
type: Concern
concern_id: closing-the-default-commit-path-routes
mission: 
tickets: []
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-07-16T11:11:25+09:00
first_seen: 2026-06-29T13:18:46+09:00
last_seen: 2026-07-16T12:06:03+09:00
severity: moderate
status: accepted
compound: true
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Promoted to ticket 20260716163001-commit-sh-argument-and-subject-hardening.md (2026-07-16 triage-to-zero): wire check-subject.sh into commit.sh with an LC_ALL pin. Risk now tracked in the queue.
closed_at: 2026-07-16T17:09:32+09:00
---

# Closing the default commit path routes every commit through a byte-based length cap

## Description

A sequencing trap: these two are safe only because they are currently disconnected, and the prescribed fix for the first is what connects them. `the-commit-subject-rule-binds-on` records that `commit.sh` — the script `/commit` and `archive.sh` both route through — never calls `check-subject.sh`, so the sanctioned path is unguarded; its fix is "call `check-subject.sh` at the top of `commit.sh` and fail non-zero. One line." `50-char-cap-is-byte-based` records that `check-subject.sh` measures with `wc -m`, which counts **bytes** under a C/POSIX locale, so a multibyte subject false-trips at up to 3x its true character length. Apply the one-liner exactly as written and every sanctioned commit — including every `/drive` archive — starts flowing through that cap: under a non-UTF-8 locale a Japanese subject over roughly 17 characters is rejected on the default path, in a repository whose developer writes Japanese. Today the byte bug is contained to the guard surface, which is why it has sat at low for weeks; the fix for its neighbour is what would make it bite. The dependency **is** the finding: the locale pin is a prerequisite of the `commit.sh` call, not an independent cleanup, and nothing in either file records that ordering.

## How to Fix

Pin the locale in `check-subject.sh` **first** (measure characters, not bytes — e.g. export `LC_ALL` to a UTF-8 locale for the measurement, or count with a tool that is not locale-dependent), with a multibyte-subject test that fails under C/POSIX before the fix. Only then add the one-line `check-subject.sh` call at the top of `commit.sh`. Record the ordering in both files so the "one line" fix is never applied on its own.

