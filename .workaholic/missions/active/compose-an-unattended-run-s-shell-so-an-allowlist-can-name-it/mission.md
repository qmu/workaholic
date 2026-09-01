---
type: Mission
title: Compose an unattended run's shell so an allowlist can name it
slug: compose-an-unattended-run-s-shell-so-an-allowlist-can-name-it
status: active
merge_policy:
created_at: 2026-09-01T10:22:05+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901101811-a-plugin-path-read-composed-with-an-assignment-prefix-cannot-be-allowlisted-so-it-stalls-the-unattended-tick.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-104910
---

# Compose an unattended run's shell so an allowlist can name it

## Goal

A tick stalled on `export CLAUDE_PLUGIN_ROOT=…; sed …` — a read of a skill's own docs.
No allowlist covers it: the first token is `export`, so every per-tool rule misses and
only `Bash(export:*)` matches, which permits anything. The rule that would have stopped
it exists (`rules/shell.md`) but is scoped `paths: '**/*.sh'`, so a session reading a
`SKILL.md` never loads it.

## Experience

A session composing a Bash call to a plugin script writes the path out in full, with the
reader as the first token and no assignment prefix, so an operator's allowlist can name
the tool that actually runs — and the session reads that rule whether or not a `.sh` file
is in its context.

## Acceptance

<!-- PROPOSED criteria - a sketch for discussion, not a plan. -->

- [x] The plugin-path Bash-call rule is stated with its measured evidence and why no
      allowlist can cover an assignment-prefixed command (#20260901102255-write-a-plugin-path-out-in-full-in-a-bash-call.md)
- [ ] A session that has loaded no `.sh` file still reads the rule (#20260901102255-put-the-shell-rule-where-every-session-loads-it.md)
- [ ] The no-prompt promise names unallowlistable shell as one of the ways it breaks (#20260901102255-forbid-unallowlistable-shell-in-a-no-prompt-run.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901102255-write-a-plugin-path-out-in-full-in-a-bash-call.md
