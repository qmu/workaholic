---
type: Feedback
title: Routine configuration has no source of truth in the repository
kind: concern
source: discussion
created_at: 2026-07-31T16:05:17+00:00
author: noreply@anthropic.com
supersedes: 
---

# Routine configuration has no source of truth in the repository

Measured while registering [qmu/workaholic#120](https://github.com/qmu/workaholic/issues/120),
to check what `/setup-routines` would read and write. It would have nothing: the routines it is
asked to list, pull, and update leave no trace in this repository at all.

(Recorded with `source: discussion` because `create.sh` still rejects `source: development`,
the value the schema documents for a development-born concern — the defect already on record in
`20260730110715-the-sanctioned-feedback-writer-rejects-the-source-97-of-records-use.md`.)

## What the repository actually contains (2026-07-31)

`grep -rn "setup-routines"` across the tree matches nothing, and no artifact of any kind
describes a Claude Code Web routine: not the routine's schedule, not its prompt, not which
repository it targets, not which Slack channel it posts to. The three templates the issue names
— "[FB] PR Creation / Issue Close", "Merged PR Notification", "Auto Drive and Report" — exist
only as configuration held outside the repository. This very run is an instance of the first
one, and nothing in the checkout it is operating on says so.

The two documents that come closest are `docs/proposal-loop-runbook.md` and
`docs/drive-loop-runbook.md`. Both are prose instructions for a **different mechanism** — a
server `crontab` line invoking headless `claude -p` — recorded under decision C1/G4 as "server
cron first, Claude Code Web later". Neither is a template a script could read, neither names
any of the three routines above, and their `## 3` sections are provisioning steps for a human.

## The constraint the fix has to face rather than route around

Both runbooks close with the same rule, stated as policy rather than convenience:

> Do not install the crontab from an agent session — applying a standing outward-facing process
> is the developer's act; this page is the instruction.

`/setup-routines`' third asked-for capability — "update a repository's routine configuration to
add, remove, or refresh a routine" — is exactly that act. So the skill cannot be specified as a
straight automation of the runbooks; the design has to decide what an agent may apply
unattended, what it may only propose for a developer to apply, and where that line sits now
that the mechanism is a hosted routine rather than a root crontab.

## Why this shapes the fix rather than merely delaying it

A skill that lists routines needs a source of truth to list *from*, and the `.workaholic/`
layout is a **closed** structure: the 11 permitted top-level directories are fixed in
`hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` table, and a new artifact
area is a deliberate amendment registered in the same commit that first writes to it. Whether
routine configuration becomes a new registered area, rides in an existing one, or stays
deliberately outside the repository is a decision the mission has to take up front — it
determines whether the skill can be read-only at all, and it cannot be discovered later without
either a layout amendment or a guard block.
