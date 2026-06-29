---
origin_pr: 59
origin_pr_url: https://github.com/qmu/workaholic/pull/59
origin_branch: work-20260628-002047
origin_commit: bfe423a
created_at: 2026-06-29T13:18:46+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# git commit-msg hook escapes the POSIX lint gate

## Description

A git hook must be named exactly `commit-msg` (no extension), but `hooks/posix-lint.sh` only scans `*.sh`, so the new git hook is invisible to the POSIX gate (see [e2fdcf0](https://github.com/qmu/workaholic/commit/e2fdcf0) in `plugins/workaholic/hooks/git/commit-msg`). It is POSIX `#!/bin/sh -eu` by construction today, but a future bashism in it would not be caught by CI. The shared logic deliberately lives in `lib/check-subject.sh` (which `posix-lint` *does* scan) to keep the lintable surface maximal.

## How to Fix

If more git-native hooks are added under `hooks/git/`, either extend `posix-lint.sh` to scan that directory by name or keep the extensionless hooks trivially POSIX with all real logic in lintable `lib/*.sh` files.
