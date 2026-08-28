---
type: Mission
title: Finish the retirement the loop cannot complete
slug: finish-the-retirement-the-loop-cannot-complete
status: achieved
merge_policy:
created_at: 2026-08-27T23:21:32+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260827231916-finish-the-retirement-the-loop-cannot-complete.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260827-234102
---

# Finish the retirement the loop cannot complete

## Goal

`retire-claim.sh` takes three acts on a claim proved `superseded`: close the pull
request, delete the remote branch, reap the worktree. Act 2 fails on every tick in
the container the loop runs in, so the claim table grows exactly as before while the
step reports `0 retired`.

## Scope

The retirement writer, its `/moderate` caller, the claim protocol's proofs table
and the `verify-retire` drill. Out of scope: retiring the `superseded` verdict,
loosening the proof gate, or teaching the oracle to ignore a branch — nothing
here merges, reverts or releases a claim.

## Experience

A claim the loop has proved empty stops accumulating. Either its branch is gone and
the claim is retired, or exactly one person has been told once, by name, which
branches are waiting on them and why. Reading `retire-claims` says which act is
blocked, and a standing blocked retirement stops reading as a fresh hourly finding.

## Acceptance

- [x] A refused delete is reported under its own word, naming the blocked act and the acts that stand. (#20260827232222-give-a-refused-delete-its-own-reported-word.md)
- [x] A blocked unit reaches its claim holder exactly once, naming the branches and the refusal. (#20260827232222-ask-the-holder-for-the-branches-left-undeleted.md)
- [x] `verify-retire` drills the blocked retirement with no network, with a row that breaks the seam. (#20260827232222-drill-the-blocked-retirement-with-no-network.md)

## Changelog

- 2026-08-27: proposed from issue #667 (`depth`).
- 2026-08-27 — ticket archived — 20260827232222-reproduce-the-refused-branch-delete-and-name-it.md
- 2026-08-27 — ticket archived — 20260827232222-give-a-refused-delete-its-own-reported-word.md
- 2026-08-27 — ticket archived — 20260827232222-retry-a-refused-delete-or-record-no-transport.md
- 2026-08-27 — ticket archived — 20260827232222-report-what-stands-and-what-is-outstanding.md
- 2026-08-27 — ticket archived — 20260827232222-ask-the-holder-for-the-branches-left-undeleted.md
- 2026-08-28 — ticket archived — 20260827232222-stop-restating-a-standing-blocked-retirement.md
- 2026-08-28 — ticket archived — 20260827232222-drill-the-blocked-retirement-with-no-network.md
- 2026-08-28 — ticket archived — 20260827232222-write-the-blocked-retirement-into-the-documents.md
- 2026-08-28 — mission achieved — mission.md
