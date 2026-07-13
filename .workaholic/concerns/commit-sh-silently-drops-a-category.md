---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
last_seen: 2026-06-30T02:27:29+09:00
first_seen: 2026-06-29T13:18:46+09:00
concern_id: commit-sh-silently-drops-a-category
severity: low
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# commit.sh silently drops a --category placed after its positional args

## Description

`commit.sh` parses option flags (`--category`, `--skip-staging`) only at the front of its argument list — the parse loop breaks on the first non-flag token, so a `--category` placed after the six positional args is silently consumed as a `[files...]` entry and the `Category:` trailer goes missing with no error (see [a62d99c](https://github.com/qmu/workaholic/commit/a62d99c) in `plugins/workaholic/skills/commit/scripts/commit.sh`). The missing trailer is invisible to `verify.mjs`; only a temp-repo dry-run surfaces it.

## How to Fix

Always pass flags before the positional `title why changes concerns insights verify` args (the `/commit` doc now states this), and consider making `commit.sh` error on an unrecognized trailing `--flag` instead of treating it as a file path.
