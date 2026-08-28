---
type: Mission
title: Finish a proved retirement where the write is permitted
slug: finish-a-proved-retirement-where-the-write-is-permitted
status: active
merge_policy:
created_at: 2026-08-28T10:21:05+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260828101734-finish-a-proved-retirement-where-the-write-is-permitted.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260828-104111
---

# Finish a proved retirement where the write is permitted

## Goal

The loop proves a claim `superseded`, closes its pull request, and is then refused the
branch delete by a session-type 403 both transports agree on — so the branch stays and a
person is handed `git push origin --delete`. Move that act to where the write is
permitted, on `release-note-draft.yml`'s precedent.

## Scope

Act 2 only. `superseded` stays a proof and gains no verdict word; `lib/claims.sh` emits
nothing new; `retire-claim.sh` keeps its three-act vocabulary.

## Experience

When the loop proves a claim empty, the claim leaves the table with nobody touching
anything: the pull request closes, CI deletes the branch, the worktree is reaped. The
operator is asked only when CI also refused, and is then still told the unit, the exact
branch and what already stands.

## Acceptance

<!-- PROPOSED - a sketch for discussion. Approval replans this to drive-ready. -->

- [x] A `superseded` branch is deleted by CI, the verdict re-proved at the act and every
      refusal named at exit 0 (#20260828102230-re-prove-the-verdict-inside-ci-and-bound-what-may-be-deleted.md)
- [x] A CI-taken delete is reported as CI's (#20260828102230-report-which-executor-took-the-branch-delete.md)
- [x] `retire-blocked:` fires only after CI also refused, key/gate/addressee/cap
      unmoved (#20260828102230-narrow-the-blocked-question-to-what-ci-could-not-take.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-28 — ticket archived — 20260828102230-derive-the-ci-retirement-candidate-set-with-no-new-store.md
- 2026-08-28 — ticket archived — 20260828102230-re-prove-the-verdict-inside-ci-and-bound-what-may-be-deleted.md
- 2026-08-28 — ticket archived — 20260828102230-add-the-workflow-that-takes-the-refused-branch-delete.md
- 2026-08-28 — ticket archived — 20260828102230-narrow-the-blocked-question-to-what-ci-could-not-take.md
- 2026-08-28 — ticket archived — 20260828102230-report-which-executor-took-the-branch-delete.md
- 2026-08-28 — ticket archived — 20260828102230-drill-the-ci-retirement-with-no-network.md
