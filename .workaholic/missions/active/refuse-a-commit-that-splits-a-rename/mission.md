---
type: Mission
title: Refuse a commit that splits a rename
slug: refuse-a-commit-that-splits-a-rename
status: active
merge_policy:
created_at: 2026-08-21T15:15:41+09:00
author: a@qmu.jp
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260821151526-a-convergent-migration-lands-its-deletions-and-leaves-its-additions-untracked.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260823-151809
---

# Refuse a commit that splits a rename

## Goal

One `/drive` run erased 50 concern records from `main`. `list-open-concerns.sh` — documented as
a pure read — ran `migrate-concerns.sh`, which wrote `concerns/` → `feedbacks/` into the
working tree and, by its own contract, staged nothing. So the 50 new files were untracked. Then
`/report` Phase 4 called `commit.sh` with default staging: `git add -u` staged the 50 **old**
deletions and skipped the untracked additions. A deletion-only commit merged. The same cause
dropped the story body `/report` had just written — always a new file — leaving the tracked
index update merged and pointing at nothing. Both took a follow-up commit to recover.

The defect is an **asymmetry**: `commit.sh` lists untracked files as a warning, and it was
printed. The migration's deletion half is staged **silently**, by `git add -u`'s semantics. So
holding a rename's two halves together rests entirely on a human reading a warning.

## Scope

`commit.sh`'s staging step, the migration scripts' index contract, and the two seams that call
`commit.sh` after writing new files. Not the migrations' own correctness.

## Experience

A commit taken straight after a migration cannot contain only its deletions. A `/report` run
that writes a story never lands the index without the story.

## Acceptance

- [ ] A split rename is refused mechanically, not warned about (#20260821151550-refuse-a-commit-that-splits-a-rename.md)
- [ ] The seams that write new files name them, so default staging is never load-bearing (#20260821151550-name-the-files-the-writing-seams-must-stage.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
