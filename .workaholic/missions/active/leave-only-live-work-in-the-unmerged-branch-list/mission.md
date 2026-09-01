---
type: Mission
title: Leave only live work in the unmerged-branch list
slug: leave-only-live-work-in-the-unmerged-branch-list
status: active
merge_policy:
created_at: 2026-09-01T11:24:50+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260901112130-the-unmerged-branch-list-is-30-long-and-22-of-them-are-dead.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260901-115944
---

# Leave only live work in the unmerged-branch list

## Goal

Measured 2026-09-01: `--no-merged` returns 30 branches, 22 dead — 17 merged (squash-merge
leaves no ancestry; `delete_branch_on_merge` is forward-only) and 5 closed unmerged.
`superseded` reaches none, so four are re-offered hourly. Five open pull requests also
outlived their head branch and can never merge.

## Scope

The CI retirement's candidate readings, one `/moderate` reading beside `operator-pulls`, a
diagnosis of the in-flight gate. Not `superseded`.

## Acceptance

- [x] A merged branch and a closed-unmerged one are each their own retirement candidate,
      proved from the pull request, and CI deletes them. (#20260901112558-name-a-merged-branch-as-a-retirement-candidate.md)
- [ ] An open pull request whose head branch is gone is named where the operator reads it. (#20260901112558-name-an-open-pull-request-with-no-head-branch.md)
- [ ] Why the gate let five duplicates through is localized, and a drill proves the new
      readings offline. (#20260901112558-localize-why-the-in-flight-gate-let-a-duplicate-through.md)

## Experience

The unmerged-branch list names only work somebody could still act on. A branch whose pull
request merged or was closed unmerged retires without a person; an open pull request with
no head branch is named where the operator reads it; and why two runs implemented one
defect five times is written down rather than guessed at.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-01 — ticket archived — 20260901112558-read-a-claim-branch-s-pull-request-state.md
- 2026-09-01 — ticket archived — 20260901112558-name-a-merged-branch-as-a-retirement-candidate.md
- 2026-09-01 — ticket archived — 20260901112558-name-a-closed-unmerged-branch-as-its-own-candidate.md
