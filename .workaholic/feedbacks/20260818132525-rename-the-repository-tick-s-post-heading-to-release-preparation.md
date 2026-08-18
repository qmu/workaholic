---
type: Feedback
title: Rename the repository tick's post heading to Release Preparation
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-18T13:25:25+00:00
author: a@qmu.jp
supersedes: 
---

# Rename the repository tick's post heading to Release Preparation

Source: https://github.com/qmu/workaholic/issues/501

The 2026-08-18 rename (issue #485) moved the routine's Slack root from
`📦 Release status` to `📦 Prepare release`, matching the `/prepare-release` command
name. The developer's ruling on seeing the applied heading: it should be
**`📦 Release Preparation`** — a noun phrase naming the report, not the command's
imperative verb form.

The heading carries no dedup weight (the notify lookup keys on `deploy:<digest>`), so
the change costs nothing at the cutover. Affected places: the `prepare-release.md`
routine template's prompt, `notify/reference/notifications.md`'s copy of the shape, the
ship skill's status-line section, and whatever tests pin the shape byte-identical. The
live `[Prepare Release]` routines' prompts need the same one-line update once this
lands.
