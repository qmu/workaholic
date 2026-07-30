---
type: Feedback
title: The proposal cursor is runner-local, so an ephemeral runner cold-starts every tick and proposes nothing
kind: concern
source: discussion
created_at: 2026-07-30T10:19:11+00:00
author: noreply@anthropic.com
supersedes: 
---

# The proposal cursor is runner-local, so an ephemeral runner cold-starts every tick and proposes nothing

## Description

`/propose` step 2 stops the run when `cursor.sh read` reports `initialized: true`:
pre-existing feedback is treated as already-seen, which is the right cold-start
behaviour for a server that starts once. But `.workaholic/proposal-cursor` is
**runner-local, git-ignored state** (decision C1), and a scheduled routine running
on Claude Code on the web gets a **fresh clone in an ephemeral container on every
tick**. So every tick is a cold start: the cursor bootstraps to the current
`origin/main` tip, the batch reports a healthy-looking `{"initialized": true}`,
and it proposes nothing — permanently, and silently, because a bootstrap report
is indistinguishable from a normal quiet run in the cron log.

Measured on this run (2026-07-30): the cursor file was absent, `cursor.sh read`
bootstrapped to `e2f0732`, and the window since the last proposal commit
(`dbec5c0`, "Register draft-gate feedback and draft mission") in fact held **9
new feedback records** — every one of which the bootstrap-and-stop path would
have skipped without saying so.

The runbook's replay mechanism ("write an older commit sha into the file by
hand") is the only recovery, and it is a developer's manual act — unavailable to
a headless tick, which is the exact caller that needs it.

## How to Fix

Derive the cursor from something the repository already carries instead of from
runner-local disk, so it survives a fresh clone: the newest commit whose subject
matches `^Propose mission ` on the base (the loop's own ledger, per the runbook's
Observability section) is already a durable, exact record of what the batch has
processed, and `list-proposed-refs.sh` already dedups the window on top of it.
Keep the file as a fast path when present, but fall back to the ledger rather
than to "everything before now is seen".

Whatever the fix, `initialized: true` should not read as success in the run
report — a cold start that skips a non-empty window is a distinct outcome from
silence and should be reported as one.
