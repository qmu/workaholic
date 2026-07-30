---
type: Mission
title: Adopt a release-branch staging tier with durable ship records
slug: adopt-a-git-flow-branching-model-with-durable-ship-records
status: approved
merge_policy: auto
created_at: 2026-07-30T05:13:37+00:00
author: noreply@anthropic.com
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260730051313-move-branching-model-from-github-flow-to-git-flow-for-qa-and-ship-traceability.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Adopt a release-branch staging tier with durable ship records

## Goal

Today every unit's branch merges straight from `work-*` into `main` — GitHub Flow, trunk-based,
with no `develop`, `release/*`, or `hotfix/*` tier anywhere in `branching`, `/drive`, or `/ship`.
The source feedback asked to move toward Git Flow, for **QA and traceability**: with only one
tier, "what shipped to production, and when" is answerable only by reading merge commits on
`main`, and there is no staging tier where a batch of merged units can be verified together
before it reaches production.

**The design question is now settled**, per a follow-up Slack discussion in `#dev-workaholic`
(see the Changelog): full Git Flow is not the destination. The chosen shape is a deliberate
middle ground — in the requester's own words, "not exactly the same as Git Flow, but a middle of
GitHub Flow and Git Flow":

- `main` stays the default/production branch, exactly as today. GitHub-Flow-style, unchanged.
- **Exactly one new tier is added: `release/*`.** No `develop`, no `hotfix/*`.
- `release/*` only enters the picture at deploy/promotion time, not at per-unit merge time. A
  release branch is cut from `main` — as part of `/ship`'s flow or a new promotion step — to
  serve as a staging/QA window before production confirmation. Once confirmed, it is what
  actually gets deployed/tagged.
- The durable "what shipped, when" record attaches to the **release branch itself** (which
  `main` commits it carries, when it was cut, when it was confirmed/deployed) as a new, separate
  artifact — it does not restructure the existing per-unit `.workaholic/release-notes/` + story
  evidence mechanism, which stays exactly as it is today.

Because the per-unit claim mechanics are unchanged, the two hardest open questions from the
original draft — reconciling the claim protocol against a second base, and what `merge_policy`
means under two merge targets — are **resolved by dropping them, not by answering them**: there
is still exactly one merge target for a unit (`main`), so neither question arises.

One assumption from the originating discussion was already corrected in the feedback record and
still holds: **`/ship` does not produce zero artifacts today.** It already writes
`.workaholic/release-notes/<branch>.md` pre-merge, appends a Deployment Evidence block to
`.workaholic/stories/<branch>.md`, and copies that story into the PR body. That mechanism is
untouched by this mission; the release-branch ship record is additive, not a replacement.

## Scope

Proposed — provisional until approval replans this to drive-ready.

In scope:

- **`release/*` is the only new tier.** No `develop`, no `hotfix/*`. `main` remains the default
  and production branch, exactly as today.
- **Per-unit claim/branch/PR mechanics are UNCHANGED and out of scope for modification.** The
  1:1 unit↔claim↔branch↔worktree↔PR invariant, `claim.sh`'s cut from `origin/main`, the
  "unmerged remote branches are the claims in flight" reader, and `merge_policy: auto`'s existing
  meaning (auto-merge a unit's branch into `main` without asking) all stand as they are today.
  This mission does not touch any of them.
- **Add a `release/*` cut-and-promote flow to `/ship`** (or a new promotion step): cut a release
  branch from `main` at deploy/promotion time, hold it open as a staging/QA window, and on
  confirmation treat it as what is actually deployed/tagged.
- **Define a ship-record format for release branches** as a new, separate artifact from the
  existing per-unit `.workaholic/release-notes/` + story mechanism — recording which `main`
  commits a release branch carries, when it was cut, and when it was confirmed/deployed.
- **Update `hooks/guard-git-branch.sh`'s allowlist for `release/*` naming**, so the branch-name
  gate recognizes the new tier alongside the existing `work-YYYYMMDD-HHMMSS` pattern.
- **Land the change across every surface that names the model**: `branching`, `ship` skills and
  commands, the layout allowlist if a new artifact directory appears for the release-branch ship
  record, `docs/drive-loop-runbook.md`, `docs/loop-engineering-workflow.md`, `README.md`,
  `CLAUDE.md`, and a regenerated `outputs/`.

Out of scope:

- A `develop` tier.
- A `hotfix/*` tier.
- Any change to the per-unit claim protocol (claim/branch/worktree/PR mechanics, or what
  `merge_policy: auto`/`review` means for a unit merging into `main`).
- Retiring GitHub Release publishing (`publish-release.sh`) — it may be re-pointed, not removed.
- Rewriting already-merged history to fit the new model.
- Replacing the repository-as-coordination-medium claim model with a lock or a server.

## Experience

Provisional (see Scope). The demanded, observable behavior:

- A developer can name any production deploy and trace it back — through the release branch's
  own durable record — to which `main` commits it carried, when the release branch was cut, and
  when it was confirmed/deployed. Grep and `git log` answer it without opening GitHub.
- Merged work reaches a `release/*` staging window where it can be QA'd as a batch before it
  reaches production, so a unit landing on `main` is no longer the same event as a production
  release.
- Per-unit claim/drive/ship behavior for `auto` and `review` units is observably identical to
  today — nothing about landing a unit on `main` changes.
- `/ship`'s (or the new promotion step's) `release/*` cut-and-confirm flow runs without ever
  asking (`AskUserQuestion`) and never overrides a gate.
- Every existing invariant still holds: one unit, one claim, one branch, one worktree, one PR;
  a merge into `main` still releases a claim by definition.

## Acceptance

**PROPOSED sketch for discussion — not a plan.** Approval replans this mission to drive-ready.

- [ ] A design record in the feedback stream states the chosen tier set (`release/*` only) and
      names the alternatives (full Git Flow, a `develop`-only tier) that were rejected.
- [ ] `/ship` (or a new promotion step) implements a `release/*` cut-from-`main` flow: cut,
      staging/QA window, confirmation, and what is actually deployed/tagged.
- [ ] The release-branch ship-record format is implemented as a new, separate artifact from
      `.workaholic/release-notes/`, naming the `main` commits carried, cut time, and
      confirmation/deploy time — cross-referenced with the release branch.
- [ ] `hooks/guard-git-branch.sh` and any relevant `branching`/`ship` scripts recognize `release/*`
      as an allowed branch-name form, alongside the unchanged `work-YYYYMMDD-HHMMSS` pattern.
- [ ] The per-unit claim protocol (`drive/SKILL.md`'s Claims section, `claim.sh`,
      `lib/claims.sh`) is verified unchanged by this mission — no edits beyond doc cross-references.
- [ ] Every doc that describes the branching model tells the truth in the same change:
      `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `docs/drive-loop-runbook.md`,
      `docs/loop-engineering-workflow.md`.
- [ ] `node scripts/build-plugins/build.mjs` regenerated `outputs/`, and `verify.mjs`,
      `validate-metadata.mjs`, `test-workflow-scripts.mjs`, and `layout-doctor.sh .` all pass.
- [ ] The first ticket in the set is exploratory — a written survey of `/ship`'s current merge
      flow and where a `release/*` cut-and-promote step fits — per the scoping note carried with
      the original ask.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-07-30 — Registered as a draft mission by the proposal batch from feedback
  `20260730051313-move-branching-model-from-github-flow-to-git-flow-for-qa-and-ship-traceability.md`
  (GitHub issue #104, raised by tamura_yoshiya in `#dev-workaholic`). Unowned and unapproved:
  `/mission approve adopt-a-git-flow-branching-model-with-durable-ship-records` is the next step.
- 2026-07-30 — Revised per further Slack discussion in `#dev-workaholic`: dropped the `develop`
  and `hotfix/*` tiers and dropped any change to the per-unit claim protocol. `main` stays the
  default/production branch exactly as today, and the mission now adds only a single `release/*`
  staging tier, cut from `main` at the `/ship` promotion step, with its own durable ship record
  separate from the existing per-unit release-notes mechanism. Still draft and unowned:
  `/mission approve adopt-a-git-flow-branching-model-with-durable-ship-records` is still the next
  step.
- 2026-07-30 — mission approved — merge_policy: auto — mission.md
