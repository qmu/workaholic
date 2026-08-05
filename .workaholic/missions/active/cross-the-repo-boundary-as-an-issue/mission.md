---
type: Mission
title: Cross the repo boundary as an issue
slug: cross-the-repo-boundary-as-an-issue
status: active
merge_policy: 
created_at: 2026-08-05T10:13:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
feedback: [20260805101319-retire-request-cross-repo-asks-become-fb-issues-on-the-target.md]
claim: work-20260805-101736
---

# Cross the repo boundary as an issue

## Goal

The developer's 2026-08-05 ruling: `/request` — which writes a ticket file into
another repository's checkout — is retired. A cross-repository ask should travel
as a **GitHub issue on the target**, because that is exactly the intake the
target's [Propose] routine already ingests: the issue fires the routine, which
records the feedback and judges the proposal inside the target's own loop. The
crossing becomes an artifact the target's owners see natively, instead of a file
appearing in their tree with no event attached.

## Experience

A developer types `/fb` with a target repository and an ask. The session
composes the issue in the target's vocabulary, applies the masking judgment,
and shows **one** verbatim confirmation — destination, visibility, exact body —
that cannot be skipped. On confirmation (and a scan pass) it opens the issue
via `gh issue create` and reports the URL. The target's [Propose] routine picks
it up like any inbound report. `/request` no longer exists, every document
names the issue path as the only sanctioned crossing, and the no-matcher-can-
replace-the-human-gate rationale survives in the feedback skill.

## Acceptance

- [ ] /fb with a target repository opens the ask as an issue there after the one verbatim confirmation, writing no file into the target checkout (#20260805101337-give-fb-a-cross-repo-issue-mode.md)
- [ ] /request is gone, its load-bearing gate knowledge is relocated not deleted, and every document names the issue path as the only sanctioned crossing (#20260805101337-retire-the-request-command-and-relocate-its-gate.md)

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
