---
type: Feedback
title: scan-window.sh passes the tickets JSON to jq on argv, so /catch dies past ~1,400 tickets
kind: concern
source: discussion
created_at: 2026-07-30T10:23:19+00:00
author: noreply@anthropic.com
supersedes: 
---

# scan-window.sh passes the tickets JSON to jq on argv, so /catch dies past ~1,400 tickets

Reported by @tamurayoshiya as GitHub issue
[#110](https://github.com/qmu/workaholic/issues/110), titled `[FB]` — a feedback
submission, recorded here in the reporter's own account.

## Description

`skills/catch/scripts/scan-window.sh` does not run to completion on a repository with a
large ticket archive, which makes `/catch` unusable there. The tickets JSON is passed to
jq on argv via `jq --argjson tickets "$TICKETS"` (around line 239). Once `.workaholic/`
holds more than roughly 1,400 tickets, that argument exceeds `ARG_MAX` and jq exits 126
with `Argument list too long`, producing empty output. From the caller's side the scan
just comes back empty and `/catch` stops in Phase 0 without producing a report.

Reproduction depends only on the total ticket count — it is independent of commit volume
and of the window passed to the command. Any repository whose combined
`todo`/`archive`/`icebox`/`abandoned` count crosses the threshold hits it
deterministically. It reproduced 100% of the time on a repository with an archive of
1,400+ tickets.

As a workaround the reporter ran a copy of the script in a temp directory with that one
call switched from argv to a file — `--slurpfile` — and the report generated fine.

## How to Fix

The reporter's proposed fix, which looks like the natural one upstream: write the JSON to
a temp file, read it with `jq --slurpfile tickets <file>`, and adjust the references to
`$tickets[0]`.

The reporter also asked that other large JSON payloads in the same script (stories,
missions, deployments) be audited at the same time, since they would fail the same way as
those trees grow. Checked while registering this record: only the `MISSIONS` block passes
JSON on argv — line 238 `--argjson list "$MLIST"` alongside the reported line 239 — so
`$MLIST` carries the same defect on a slower-growing tree. `STORIES` (line 268) and the
deployments payload (line 312) already reach jq through stdin (`jq -Rs`), and the argv
values at lines 86-89 are small and bounded. So the audit resolves to one jq invocation
with two payloads, not four.

One note from the reporter for whoever makes the change: the script resolves the mission
helper scripts relative to its own directory, so running a copy from elsewhere breaks
`SCRIPT_DIR`. That is not a problem when patching the script in place — only when using a
copy to verify, where `SCRIPT_DIR` has to be pinned to an absolute path.
