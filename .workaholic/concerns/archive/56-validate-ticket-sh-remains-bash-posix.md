---
origin_pr: 56
origin_pr_url: https://github.com/qmu/workaholic/pull/56
origin_branch: work-20260624-140219
origin_commit: e78465d
created_at: 2026-06-24T21:39:11+09:00
severity: low
status: resolved
resolved_by_pr: b0e57c9
resolved_by_commit: 
---

# `validate-ticket.sh` remains bash (POSIX inconsistency)

## Description

`rules/shell.md` mandates POSIX `#!/bin/sh`, but `validate-ticket.sh` is `#!/bin/bash` with `[[ ]]`/`=~`. This branch made a minimal in-place tightening in bash and wrote the new sibling guard in POSIX sh; the inconsistency is a smell (`plugins/workaholic/hooks/validate-ticket.sh`).

## How to Fix

Full POSIX conversion of `validate-ticket.sh` as separate housekeeping.
