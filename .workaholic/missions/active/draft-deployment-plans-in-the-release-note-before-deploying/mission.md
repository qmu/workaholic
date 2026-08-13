---
type: Mission
title: Draft deployment plans in the Release Note before deploying
slug: draft-deployment-plans-in-the-release-note-before-deploying
status: active
merge_policy:
created_at: 2026-08-13T12:35:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260813123222-change-ship-s-role-to-drafting-deploy-plans-into-release-notes-before-deploying.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260813-133929
---

# Draft deployment plans in the Release Note before deploying

## Goal

PROPOSED from issue #438. `/propose` and `/implement` merge into `main` continuously, so a
merge can no longer mean an immediate deployment. `/ship` should stop starting deployments and
instead keep a **draft deployment plan** current in the Release Note: per `Deployments` target,
what needs deploying and the verification that needs. Scope is that drafting phase, the note's
plan section, and the consolidation feeding it — not the `release/*` window or §6 promotion.

## Experience

Running `/ship` against the latest `main` deploys nothing. It leaves a Release Note whose plan
says, per target, what is waiting to deploy and how it would be verified — and the developer
who reads it instructs the deploy, which records its result there.

## Acceptance

PROVISIONAL sketch — the interrogation that replans this sharpens it.

- [ ] The note carries a plan section: per target, what needs deploying and how it is verified. (#20260813123903-add-a-deployment-plan-section-to-the-release-note.md)
- [ ] `/ship` drafts that plan instead of deploying; a deploy needs the developer's instruction. (#20260813123903-make-ship-draft-the-plan-instead-of-deploying.md)
- [ ] An instructed deployment leaves its verification method and report in that same note. (#20260813123903-record-the-verification-method-and-its-report.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-13 — ticket archived — 20260813123903-consolidate-per-target-deploy-state-for-the-plan.md
