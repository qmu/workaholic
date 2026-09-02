---
type: Mission
title: Prove a claim branch is empty before deleting it
slug: prove-a-claim-branch-is-empty-before-deleting-it
status: achieved
merge_policy:
created_at: 2026-08-31T20:34:43+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260831203426-superseded-proves-the-tickets-landed-not-that-the-branch-is-empty.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260902-193702
---

# Prove a claim branch is empty before deleting it

## Goal

Two branches carrying ~300 lines and a doc section that exist in no other ref were reported
finished and offered for deletion. `claims_superseded` proves the unit's tickets are archived
on the base and nothing more; these tickets landed through **other** branches, so both read
proved-empty while still holding their own work. The retirement's stated recovery — the
content is on the base — is false in exactly that case, and it is the load-bearing half. Only
a 403 refusing the delete has kept the work alive.

## Experience

A claim branch is called finished only once its own diff against the base is empty. One that
still holds work is named as stranded rather than finished, its files named, and its holder
told once — while a branch that really is empty retires exactly as it does today.

## Acceptance

- [x] `superseded` holds only when the branch's diff against the base is empty, re-derived at
      the moment of each act. (#20260831203453-refuse-to-retire-a-branch-that-still-holds-work.md)
- [x] A branch whose tickets landed but whose diff is not empty is its own state and reaches
      a person once, naming the files. (#20260831203454-tell-a-person-about-a-stranded-claim-branch.md)
- [x] A drill proves both offline and fails if a branch still holding work is offered for
      deletion. (#20260831203454-drill-the-stranded-branch-refusal-offline.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-09-02 — Reproduced offline: a branch whose tickets landed elsewhere and still holds a file present on no other ref reads stranded at both grains, an absent ref/no merge base reads unknown and never true, the CI act re-derives the same term, and the reading costs ~7.5 ms per branch — 20260831203453-reproduce-a-superseded-branch-that-still-holds-work.md
- 2026-09-02 — ticket archived — 20260831203453-reproduce-a-superseded-branch-that-still-holds-work.md
- 2026-09-02 — ticket archived — 20260831203453-read-a-claim-branch-s-own-diff-against-the-base.md
- 2026-09-02 — ticket archived — 20260831203453-refuse-to-retire-a-branch-that-still-holds-work.md
- 2026-09-02 — ticket archived — 20260831203454-tell-a-person-about-a-stranded-claim-branch.md
- 2026-09-02 — ticket archived — 20260831203454-make-the-retirement-s-stated-recovery-true.md
- 2026-09-02 — ticket archived — 20260831203454-drill-the-stranded-branch-refusal-offline.md
- 2026-09-02 — mission achieved — mission.md
