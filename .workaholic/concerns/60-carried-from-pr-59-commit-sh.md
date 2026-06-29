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

# (carried from PR #59) commit.sh silently drops a --category placed after positional args

## Description

`commit.sh` parses flags only at the front of its argument list; a `--category` after the six positional args is consumed as a file entry and the `Category:` trailer goes missing with no error (`plugins/workaholic/skills/commit/scripts/commit.sh`).

## How to Fix

Pass flags before the positional args, and consider erroring on an unrecognized trailing `--flag`.
