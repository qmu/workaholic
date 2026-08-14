---
type: Mission
title: Split routine setup into developer and repository scopes
slug: split-routine-setup-into-developer-and-repository-scopes
status: active
merge_policy:
created_at: 2026-08-14T06:48:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260814064840-split-setup-routines-into-setup-dev-routines-and-setup-repo-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260814-084725
---

# Split routine setup into developer and repository scopes

## Goal

`/setup-routines` configures the two per-developer routines and every member runs it.
The ask splits routine setup along the axis that exists: routines each developer needs
their own copy of (`[Propose]`, `[Implement]`) versus routines the repository needs
exactly one of, configured by one account. The trial repository routine named is an
hourly `/ship` keeping the release notes current.

## Experience

A developer joining runs `/setup-dev-routines` and gets their own two routines,
unchanged. The one account owning repository-scoped automation runs
`/setup-repo-routines` and gets the repository's single copy — the command saying
plainly it is not for everyone, since N copies of a repo routine is the failure.

## Acceptance

<!-- PROPOSED sketch, not a plan — the reviewer replans this to drive-ready. -->

- [ ] Routine templates carry a scope (developer vs repository), and each command configures only its own scope. (#20260814064854-split-setup-routines-into-dev-and-repo-commands.md)
- [ ] `/setup-dev-routines` reproduces today's `/setup-routines` behaviour, including the `no_transport` refusal and its setup-sheet recovery path. (#20260814064854-split-setup-routines-into-dev-and-repo-commands.md)
- [ ] A repository-scoped routine that refreshes release notes exists as a template and is configured only by `/setup-repo-routines`. (#20260814064854-add-the-hourly-release-note-repo-routine.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
