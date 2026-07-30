---
type: Mission
title: Drop the draft gate and make /drive own its worktree from refreshed main
slug: drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main
status: draft
merge_policy:
created_at: 2026-07-30T06:29:21+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260730062852-drop-draft-as-the-drive-gate-and-have-drive-create-its-own-worktree-from-refreshed-main.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Drop the draft gate and make /drive own its worktree from refreshed main

## Goal

The source feedback (Slack `#dev-workaholic`, after PR #105) makes one argument: **merging into
`main` is the approval**. Review already happened in the pull request, so a unit that reached
`main` while still carrying `status: draft` is gated twice — and the second gate,
`/mission approve <slug>`, is a manual step whose only remaining job is to undo the first.

That argument lands against exactly one axis in the repository today, and a survey of the code
narrows the mission considerably from the feedback's own framing. Both narrowings are recorded
here so approval does not re-derive them:

- **Only missions carry `draft`; tickets have no status axis at all.** A ticket's frontmatter is
  `created_at`/`author`/`type`/`layer`/`effort`/`commit_hash`/`depends_on`/`mission`/
  `merge_policy` — there is no `status` field, and `plan-units.sh` drops a ticket only for
  `claimed` or `mission_member`. So "apply this consistently to missions and tickets" is
  *already* true on the ticket side, and the correct reading of the request is **do not add one**
  — not "remove one that exists". The work is mission-side.
- **`/drive` already owns its working environment.** `claim.sh` fetches origin (failing loudly if
  it cannot), cuts a fresh `work-*` branch from `origin/main` through the sanctioned creator, and
  is born with `.worktrees/<unit-id>/`; teardown is defined (decision I6 — claim-born and
  ship-torn, with `release-claim.sh` for an abandoned unit). The one genuine gap the feedback
  points at is already ticketed and unmissioned:
  `20260729183609-drive-surveys-current-main.md` fixes `plan-units.sh` surveying a stale local
  checkout while claims come from freshly-fetched refs. So the second half of this feedback is
  **reconciliation and documentation, not new machinery**.

What is left is real, and it is the part with an open design question. Removing `draft` is not
just deleting a `status` check in `plan-units.sh`, because `approve.sh` is currently the carrier
of three separate things that the merge does *not* decide:

1. **The `merge_policy` ruling** — a mission's `auto` vs `review` is recorded *at approval*.
   Delete approval and a mission arrives on `main` with no policy. Tickets already answer this
   (`merge_policy` absent reads as `review`, the conservative default); missions must adopt the
   same rule or record the policy at creation.
2. **Ownership seeding** — `approve.sh` seeds the approver into `assignees`. The feedback
   explicitly says the surviving approval semantics should live in **ownership/claim state**, so
   this is the thing to keep, not discard: an unowned mission on `main` is claimable by anyone,
   which is already how the lens and `list.sh` treat it.
3. **The write-time floor** — `validate-mission.sh` enforces derived-owner / `## Experience` /
   `## Acceptance` only once a mission is `approved`. That floor is the reason an empty mission
   cannot authorize unattended work, and it must not evaporate with the status it keys on.
   `plan-units.sh`'s independent `no_plan` drop (acceptance `total == 0`) is the natural
   replacement gate: **a mission is drivable when it has a plan, not when someone said so.**

The prize is one fewer concept. `status` collapses toward the lifecycle it actually describes
(in flight vs ended), the approval step disappears from the loop, and the answer to "why isn't
`/drive` picking this up?" stops being "someone forgot to approve it".

## Scope

Proposed — provisional until approval replans this to drive-ready.

In scope:

- **Retire `draft` as a precondition for drivability.** A mission present on `main` in
  `missions/active/` is surveyed by `plan-units.sh`; the `not_approved` exclusion is removed and
  `no_plan` (empty `## Acceptance`) becomes the sole quality gate on the offer.
- **Decide and record the surviving status vocabulary.** Either `status` keeps only the ended
  states (`achieved | abandoned | carried`, with in-flight meaning "in `active/`"), or the axis
  is dropped from the active area entirely. This is the mission's central design decision and it
  must be written down before the code moves.
- **Move `merge_policy` off approval.** Missions adopt the ticket rule — recorded at creation,
  **absent reads as `review`** — so no mission can arrive on `main` policy-less and be driven
  under `auto` by accident.
- **Move the `validate-mission.sh` floor off `status: approved`** onto whatever the new
  drivability condition is, so an empty mission still cannot authorize unattended work.
- **Retire `/mission approve <slug>` and `approve.sh`**, folding their still-needed effects
  (owner seeding, the merge-policy ruling) into creation. `drive-authorized.sh` and the legacy
  `drive_authorized: true` tolerance go with them.
- **Update every reader in lockstep**: `plan-units.sh`, `list.sh`'s `ready_reason`,
  `summary.sh`, `mission-lens.sh`, `lib/resolve.sh`'s legacy migration, `scaffold-draft.sh`
  (a proposed mission is no longer a *draft* — it is an unowned, planless mission), and
  `list-proposed-refs.sh`'s dedup, which must keep working across the vocabulary change.
- **A living migration for existing `status: draft` missions**, in the same shape as the
  `status: active` migration already in `lib/resolve.sh` — nothing predating the change is
  orphaned or silently made drivable.
- **Reconcile the `/drive` worktree story with what is already built**: state once, in
  `drive/SKILL.md`, that the drive refreshes from origin and works in its own claim-born
  worktree, and confirm the local-`main` staleness gap is closed by
  `20260729183609-drive-surveys-current-main.md` rather than re-solved here.
- **Update the docs that tell a human to approve after merge**: `CLAUDE.md`, `commands/mission.md`,
  `commands/propose.md`, `propose/SKILL.md`, `mission/SKILL.md`, `drive/SKILL.md`,
  `docs/proposal-loop-runbook.md`, `docs/drive-loop-runbook.md`,
  `docs/loop-engineering-workflow.md` (decision I2 is amended, not deleted — the record of why
  the one-axis lifecycle was adopted stays).

Out of scope:

- **Adding any status axis to tickets.** They have none; the request is satisfied by keeping it
  that way.
- **The claim protocol itself.** One unit ↔ one claim ↔ one branch ↔ one worktree ↔ one PR is
  unchanged; `claim.sh`, `list-claims.sh`, and `release-claim.sh` keep their current behavior.
- **Re-implementing the stale-checkout fix.** That is
  `20260729183609-drive-surveys-current-main.md`, an existing unmissioned ticket; if this
  mission is approved, decide whether to adopt that ticket into it or leave it in the backlog.
- **The `release/*` staging tier** — a separate active mission
  (`adopt-a-git-flow-branching-model-with-durable-ship-records`) which explicitly leaves per-unit
  claim mechanics untouched. No overlap.

## Experience

Provisional (see Scope).

- A developer merges a PR that adds a mission with a filled `## Acceptance`. The next `/drive`
  tick claims it. Nobody runs an approve command, and nothing in the output mentions one.
- A developer merges a mission whose `## Acceptance` is still empty. `/drive` reports it in
  `excluded[]` with reason `no_plan` — the message names the missing plan, not a missing
  approval.
- `/propose` registers an unowned mission from the feedback stream and pushes it to `main`. A
  human reads it, fills in the plan, and merges the edit; from that point it is drivable. The
  word "draft" appears nowhere in the flow.
- A mission on `main` with no `merge_policy` is driven to a **pull request**, never auto-merged.
- An existing `status: draft` mission from before the change behaves identically to a new one on
  its next mission-script touch, with no hand-editing.

## Acceptance

PROPOSED criteria — a sketch for discussion, not a plan. Approval replans this mission to
drive-ready; only then may it be authorized.

- [ ] The surviving status vocabulary and the new drivability condition are written down in
      `mission/SKILL.md`'s *Lifecycle* section and in `docs/loop-engineering-workflow.md` as an
      amendment to decision I2.
- [ ] `plan-units.sh` no longer excludes a mission for `not_approved`; `no_plan` is the only
      quality drop on the mission offer, and the `excluded[]` reason vocabulary is updated.
- [ ] `merge_policy` is recorded at mission creation, absent reads as `review`, and
      `effective-policy.sh` is verified against a policy-less mission.
- [ ] `validate-mission.sh`'s owner / `## Experience` / `## Acceptance` floor fires on the new
      condition instead of `status: approved`, and archived missions are still never
      retro-blocked.
- [ ] `/mission approve`, `approve.sh`, `drive-authorized.sh`, and the `drive_authorized` legacy
      tolerance are removed, with owner seeding and the policy ruling preserved at creation.
- [ ] Every reader named in Scope is updated in the same change, and a living migration in
      `lib/resolve.sh` folds pre-existing `status: draft` missions.
- [ ] `drive/SKILL.md` states the refresh-and-isolate behavior once, and the ticket that closes
      the stale-survey gap is either adopted into this mission or explicitly left in the backlog.
- [ ] No file in `plugins/`, `docs/`, or `CLAUDE.md` instructs a human to approve a mission after
      merging it.
- [ ] `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`,
      `node scripts/test-workflow-scripts.mjs`, and `layout-doctor.sh .` all pass, with
      `outputs/` regenerated.

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->

- 2026-07-30 — Proposed by the `/propose` batch from GitHub issue #106 / Slack `#dev-workaholic`.
