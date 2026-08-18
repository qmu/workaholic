---
type: Feedback
title: Rename /fullfill to /prepare-release and update the routine notification heading
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-18T06:21:17+00:00
author: a@qmu.jp
supersedes: 
---

# Rename /fullfill to /prepare-release and update the routine notification heading

# Rename `/fullfill` to `/prepare-release`, and the routine heading with it

Reported through GitHub issue #485 (opened by `claude[bot]` via the `/fb` crossing).

Source: https://github.com/qmu/workaholic/issues/485

## The ask, verbatim in substance

Rename the `/fullfill` slash command to `/prepare-release`, and update the associated
routine's notification heading from `[Release Status]` to `[Prepare Release]` so the heading
stays consistent with the new command name.

Context given in the ask: `/fullfill` was itself a recent rename from an earlier
`/release-status`, done to follow a one-word command naming convention. This request is a
follow-up rename on that same command and routine — the goal now is for the name to describe
what the command actually does (preparing a release) rather than optimizing purely for a
single-word name. That is an explicit reversal of the naming preference that produced
`/fullfill`, stated by the ask itself.

## Scope stated in the ask

- Rename the `/fullfill` command to `/prepare-release`, including any references,
  documentation, or help text that mention the old name.
- Update the routine's notification heading text from `[Release Status]` to
  `[Prepare Release]`.

## What the ask leaves ambiguous

`[Release Status]` is the **routine name** (`skills/workaholify/routines/release-status.md`,
`scope: repository`, configured by `/setup-repo-routines`); the routine's **notification
heading** is the `📦 Release status` post root pinned in `notify/reference/notifications.md`
and byte-checked against the template by `scripts/test-workflow-scripts.mjs`. The ask names
one string and describes the other, and the two are different surfaces. Renaming both keeps
them consistent with each other and with the command, which is what the ask asks for; that
reading is recorded here rather than silently assumed.
