---
type: Mission
title: Adopt a Git Flow branching model with durable ship records
slug: adopt-a-git-flow-branching-model-with-durable-ship-records
status: draft
merge_policy:
created_at: 2026-07-30T05:13:37+00:00
author: noreply@anthropic.com
assignees: []
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

# Adopt a Git Flow branching model with durable ship records

## Goal

Today every unit's branch merges straight from `work-*` into `main` — GitHub Flow, trunk-based,
with no `develop`, `release/*`, or `hotfix/*` tier anywhere in `branching`, `/drive`, or `/ship`.
The source feedback asks to move toward Git Flow, and the reason given is **QA and traceability**:
with only one tier, "what shipped to production, and when" is answerable only by reading merge
commits on `main`, and there is no staging tier where a batch of merged units can be verified
together before it reaches production.

The direction is the ask; the design is not settled. The feedback explicitly carries a scoping
note — start by exploring the existing machinery in detail before implementing — because the
branch model is load-bearing for the claim protocol: one unit maps 1:1 to one claim, one branch,
one worktree, and one PR, and `/drive` routes each unit by its effective merge policy (`auto`
straight through `/ship`, `review` stopping at an open PR). A second merge target changes what
"ship" means, and therefore what `/drive`'s unattended routing decides.

One assumption from the originating discussion is already corrected in the feedback record and
should not be re-litigated: **`/ship` does not produce zero artifacts today.** It already writes
`.workaholic/release-notes/<branch>.md` pre-merge, appends a Deployment Evidence block to
`.workaholic/stories/<branch>.md`, and copies that story into the PR body — so the
markdown-record-plus-PR pairing exists. The open question is whether that mechanism survives a
second branch tier as-is, or needs restructuring.

## Scope

Proposed — provisional until approval replans this to drive-ready.

In scope:

- **Decide which tiers Git Flow actually introduces here** — `develop`, `release/*`, `hotfix/*`,
  or some subset. A subset is a legitimate answer; so is concluding that a `develop` tier alone
  buys the QA seam without the release-branch ceremony.
- **Reconcile the chosen model with the claim protocol.** The 1:1 unit↔claim↔branch↔worktree↔PR
  invariant, `claim.sh`'s cut from `origin/main`, and the "unmerged remote branches are the
  claims in flight" reader all assume a single base. Each needs an explicit answer, not a
  silent reinterpretation.
- **Decide `/drive`'s routing under two targets** — what `merge_policy: auto` means when the
  merge lands on `develop` rather than production, and what (if anything) promotes `develop` to
  `main`. The unattended-run guarantee (no `AskUserQuestion`, never override a gate) must hold.
- **Decide the ship-record question**: extend `.workaholic/release-notes/` + stories to record
  *which branch merged into which target and when*, or introduce a distinct ship-record document
  type separate from the GitHub-Release-oriented release note. Either way each merge event leaves
  two durable cross-referenced artifacts — an in-repo markdown record and the PR.
- **Land the change across every surface that names the model**: `branching`, `drive`, `ship`,
  `report` skills and commands, the `hooks/guard-git-branch.sh` branch-name gate, the layout
  allowlist if a new artifact directory appears, `docs/drive-loop-runbook.md`,
  `docs/loop-engineering-workflow.md`, `README.md`, `CLAUDE.md`, and a regenerated `outputs/`.

Out of scope:

- Replacing the repository-as-coordination-medium claim model with a lock or a server.
- Retiring GitHub Release publishing (`publish-release.sh`) — it may be re-pointed, not removed.
- Rewriting already-merged history to fit the new model.

## Experience

Provisional (see Scope). The demanded, observable behavior:

- A developer can name any production deploy and trace it back — through an in-repo markdown
  record and its PR — to the branch tier it came from, the units it carried, and when each
  crossed each tier. Grep and `git log` over `.workaholic/` answer it without opening GitHub.
- Merged work reaches a tier where it can be QA'd as a batch before it reaches production, so a
  unit landing is no longer the same event as a production release.
- `/drive` and `/ship` target the correct tier on their own. An unattended run never asks, never
  overrides a gate, and never merges to production a unit whose policy only authorized landing on
  the staging tier.
- Every existing invariant still holds: one unit, one claim, one branch, one worktree, one PR;
  a merge still releases a claim by definition.

## Acceptance

**PROPOSED sketch for discussion — not a plan.** Approval replans this mission to drive-ready.

- [ ] A design record in the feedback stream states the chosen tier set and the reason the
      rejected alternatives were rejected.
- [ ] The claim protocol's answer under multiple bases is written in `drive/SKILL.md`'s Claims
      section (the one place the model is stated) and implemented in `claim.sh` / `lib/claims.sh`.
- [ ] `/drive`'s routing under two merge targets is specified and implemented, with the
      no-prompt / never-override-a-gate guarantee demonstrably intact.
- [ ] The ship-record decision is implemented: every merge event into any tier leaves an in-repo
      markdown record cross-referenced with its PR, and the record names source branch, target
      branch, and timestamp.
- [ ] `hooks/guard-git-branch.sh` and `branching/scripts/create.sh` agree on the new branch-name
      grammar, with legacy `work-*` still recognized.
- [ ] Every doc that describes the branching model tells the truth in the same change:
      `CLAUDE.md`, `README.md`, `.workaholic/README.md`, `docs/drive-loop-runbook.md`,
      `docs/loop-engineering-workflow.md`.
- [ ] `node scripts/build-plugins/build.mjs` regenerated `outputs/`, and `verify.mjs`,
      `validate-metadata.mjs`, `test-workflow-scripts.mjs`, and `layout-doctor.sh .` all pass.
- [ ] The first ticket in the set is exploratory — a written survey of the current
      `/drive`/`/ship`/claim-worktree machinery — per the scoping note carried with the ask.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-07-30 — Registered as a draft mission by the proposal batch from feedback
  `20260730051313-move-branching-model-from-github-flow-to-git-flow-for-qa-and-ship-traceability.md`
  (GitHub issue #104, raised by tamura_yoshiya in `#dev-workaholic`). Unowned and unapproved:
  `/mission approve adopt-a-git-flow-branching-model-with-durable-ship-records` is the next step.
