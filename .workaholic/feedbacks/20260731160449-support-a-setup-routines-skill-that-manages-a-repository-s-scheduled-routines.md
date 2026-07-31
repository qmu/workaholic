---
type: Feedback
title: Support a /setup-routines skill that manages a repository's scheduled routines
kind: instruction
source: slack
created_at: 2026-07-31T16:04:49+00:00
author: noreply@anthropic.com
supersedes: 
---

# Support a /setup-routines skill that manages a repository's scheduled routines

Reported by the requester in Slack (#dev-workaholic), filed as
[qmu/workaholic#120](https://github.com/qmu/workaholic/issues/120). Recorded in the
reporter's own words.

## The instruction

The workaholic project should gain a `/setup-routines [repository name]` skill in Claude Code
Web that manages the scheduled routines configured for a given repository. Today routine
configuration is done ad hoc by a single person; this skill should make it a first-class,
inspectable operation.

Three routine templates exist or are planned:

- **"[FB] PR Creation / Issue Close"** — turns a Slack-reported issue into a `[FB]` GitHub
  issue and closes it via a matching PR (exists).
- **"Merged PR Notification"** — posts a Slack summary when a PR merges (exists).
- **"Auto Drive and Report"** — would run `/drive` on a schedule and report the outcome to
  Slack (not yet implemented).

`/setup-routines [repository name]` should:

1. list which of these routines are currently configured for the named repository,
2. let the caller pull the latest version of each template when creating or updating a routine,
3. update a repository's routine configuration to add, remove, or refresh a routine from its
   template.

## The future the reporter asked to design for

The requester is currently the only person configuring routines, and expects that to change: a
future redesign should let each developer configure their own routines when they join a
project, so that one developer's feedback could route to a second developer's implementation
work while a routine sends the resulting PR to a third developer for review.

`/setup-routines` should be designed with that multi-developer, per-person routing future in
mind, not a single-configurator assumption.
