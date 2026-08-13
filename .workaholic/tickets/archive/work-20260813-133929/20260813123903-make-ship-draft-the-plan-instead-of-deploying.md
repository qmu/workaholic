---
created_at: 2026-08-13T12:39:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-deployment-plans-in-the-release-note-before-deploying
merge_policy:
---

# Make ship draft the plan instead of deploying

## Overview

PROPOSED. Issue #438's steps 2–3 and the mission's centre: `/ship` stops starting a deployment and instead drafts the plan, and "the user reviews that draft and then instructs deployment". This is a change to the command's role, so it is the ticket where the ask meets written doctrine and where the reviewer's attention belongs.

What exists today (`skills/ship/SKILL.md`): `/ship` is per-unit, operating on the current branch's PR, with three standing rules stated as never optional — catch up with `main`, deploy and confirm **before** the merge, and halt when no confirmation method exists. §5 orders it: pre-check → catch up → scan → deploy → confirm → record evidence → **merge last**, gated on a passing confirmation, "so an unconfirmable change never reaches `main`". §1-3 already asks the developer to confirm the deploy procedure before running it — for an attended caller, an approval gate is present; §0 routes an unattended caller to "proceed", because `merge_policy: auto` recorded at creation *is* that authorization.

So the change is not "add an approval". It is: the drafting phase becomes `/ship`'s default outcome, and deploying becomes a separate, instructed act. Whether the merge still waits for a confirmation is the fork this ticket must resolve rather than inherit — see Open Decisions.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — what a delivery path may and may not do unattended
- `workaholic:design` / `policies/modeless-design.md` — a command whose behaviour depends on a mode is the failure this repo already legislated against
- `workaholic:implementation` / `policies/objective-documentation.md` — the doctrine change must be written where the rule is stated, not only in the changelog
- `workaholic:planning` / `policies/verify-before-building.md` — the evidence-before-merge rule is the thing being renegotiated; state the new invariant explicitly

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` — the standing rules, §0 unattended routing table, §1-3/§1-4 gates, §5 flow, §6 promotion; the role change is written here.
- `plugins/workaholic/skills/ship/reference/flow.md` — the per-step detail that must move with it.
- `plugins/workaholic/skills/ship/reference/release-tier.md` — §6's mechanics, which the mission holds out of scope; the boundary has to stay legible.
- `plugins/workaholic/commands/ship.md` — the command's one-line contract.
- `plugins/workaholic/skills/drive/SKILL.md` §6 — the `auto` merge policy routes a unit into `/ship`; if `/ship` no longer deploys, what `auto` means changes and must be restated there.
- `CLAUDE.md` (the `/ship` row, "Merge policy", "The release tier") and `README.md` — the documentation this change invalidates in the same commit.
- `.workaholic/feedbacks/20260811010237-scope-the-release-planning-loop-that-decides-what-ships.md` — the record this ask overlaps; read it before writing (see Open Decisions).

## Implementation Steps

1. Reproduce the current behaviour first: run `/ship` on a branch with a PR in this repository and record what it does at §1-3, §1-4 and §5 for the `marketplace` target, attended and via §0's unattended routing. The doctrine is dense and partly already satisfies the ask; changing it from the issue's description alone risks removing a gate that is doing work.
2. Resolve the Open Decisions below and write each resolution into the Final Report before editing the skill.
3. Insert the drafting phase: `/ship` reads the consolidation (sibling ticket), writes/refreshes the plan (sibling ticket), and reports it — as the default outcome of an invocation that is not an instructed deploy.
4. Restate the deploy path as instructed-only, and update §0's routing table so an unattended caller *never* deploys — today it answers "proceed" at §1-3.
5. State the surviving invariant explicitly wherever the old one is stated: whether a merge still requires a passing production confirmation, and if not, what now prevents an unconfirmable change from reaching `main` (the `release/*` window is the candidate, and it is §6's, not §5's).
6. Keep `/ship` one behaviour: the drafting-versus-deploying distinction must not become a first word of the argument — that is an enforcement gate, not a preference.
7. Update `drive/SKILL.md` §6 and the `merge_policy: auto` description if `auto` no longer implies a deployment, plus `CLAUDE.md`, `README.md` and the rules docs in the same commit.
8. Argument-less `node scripts/build-plugins/build.mjs`; `verify.mjs`, `validate-metadata.mjs` and `node scripts/test-workflow-scripts.mjs` green.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Does the merge still wait for a passing production confirmation?** `/ship` §5 states, as a standing rule, that deploy and confirmation happen pre-merge and the merge is gated on them — "a failed confirmation means the branch simply isn't merged (that is the rollback)". If `/ship` no longer deploys, either that gate is dropped for the unit path (and the `release/*` window becomes the only production evidence) or `/ship` splits into two invocations, the second still deploying-confirming-then-merging on instruction. The ask does not say, and dropping the gate silently would remove the repository's only pre-merge production evidence.
- **Does this supersede the release-planning loop's boundary?** FB `20260811010237` (the same author, 2026-08-11) scopes a release-planning loop that reads the unreleased range and drafts the release note, and states explicitly that it is "NOT a new agent role bolted onto `/ship`" and that §6's promotion confirmation "stays exactly the evidence-gated act it is". Issue #438 instructs approximately that bolt-on. The later instruction governs, but whether the two merge, or `/ship` drafts per target while the loop plans per batch, is a scope ruling for the developer.
- **Which caller drafts, and does `/implement` still ship?** `auto` units route through `/ship` from an unattended run. If drafting is `/ship`'s default, an `auto` unit's ship becomes a draft-and-stop, which changes what `/implement` reports as `shipped`.

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- `/ship` invoked without a deploy instruction performs no deployment and leaves a current plan; the observed behaviour matches the skill's written flow.
- No unattended caller can reach the deploy step — §0's routing table says so explicitly for every seam.
- The surviving pre-merge invariant is stated in the skill, and every document that stated the old one (`CLAUDE.md`, `README.md`, `drive/SKILL.md` §6, `commands/ship.md`) is updated in the same commit.
- `/ship` still has one behaviour: nothing dispatches on the first word of its argument.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproduction rerun after the change, pasted before/after into the Final Report.
- `node scripts/test-workflow-scripts.mjs`, `build.mjs`, `verify.mjs`, `validate-metadata.mjs` green.
- `bash plugins/workaholic/skills/report/scripts/doc-drift.sh` clean for the touched docs.

**Gate** — what must pass before approval:

- Both Open Decisions resolved in writing, the before/after reproduction, and all suites green.

## Considerations

- This is the ticket a reviewer should read first. It renegotiates a rule the skill calls "none optional", and the mission's other tickets are mechanical next to it.
- For a deploy-on-merge target — this repository's own — "don't deploy on merge" cannot be satisfied by `/ship` alone: the merge *is* the deployment, and only the tag/release step is separable. The honest reading is that such a target's plan describes the release publish, and that the `release/*` window is where "merged ≠ deployed" actually lives.
- The accepted-risk bypass and the non-overridable `secret` stop must survive untouched. A refactor of this size is exactly where a hard gate gets quietly reclassified.

## Final Report

Development completed as planned.

### Step 1 — reproduction of the current behaviour

Reproduced on this repository, **read-only seams only**, before editing the skill:

- §1-4 gate input — `read-deployments.sh` → `has_confirmation=true` (the `marketplace`
  target declares `confirmation_method: other` and a non-empty `## Confirmation`), so the
  hard gate passes and never halted this repository.
- §3 capability — `check-confirmation-capability.sh other` →
  `{"capable": true, "hint": "Project-defined method; ensure its ## Confirmation tooling
  is available in this ship environment."}` — advisory, as documented.
- §4 ticket guard — `check-todo.sh` → `{"clean": false, "count": 11}`, informational and
  non-blocking, as documented.
- §1 pre-check — `pre-check.sh work-20260813-133929` → `{"found": false}` (no PR on the
  claim branch at the time), the documented "run `/report` first" stop.

**What was NOT reproduced, and why.** Steps 3-6 (deploy, confirm, record, merge) could not
be run: executing them means deploying and merging a real pull request — an outward,
irreversible act this unattended run has no instruction to take, and the safety floor
forbids it. Their behaviour was read from `SKILL.md` §5 and `reference/flow.md`, which are
the normative statement of it. **After the change**, the same four read-only seams behave
identically — none of them was touched: the gate, the capability check, the ticket guard
and the pre-check are unchanged in code and in contract. What changed is that §5 no longer
*reaches* a deploy step, and `/ship`'s §0 row for §1-3 now says "never deploy" where it
said "proceed". The before/after difference is therefore entirely in the flow's shape, and
the reproduction confirms the surviving gates were not disturbed.

### Open Decisions — resolved

- **Does the merge still wait for a passing production confirmation?** **No — and the
  evidence is relocated, not dropped, which is stated in three places rather than
  implied.** With `/ship` no longer deploying there is nothing pre-merge to confirm, so
  §5's merge is gated on the branch-safety scan, the mandatory catch-up, and §1-4's
  requirement that a confirmation method *exist* — not on an executed confirmation. The
  production evidence moves to the `release/*` promotion (§6), which already runs the
  target's `## Confirmation` against the window's tip. This is not a new invention: the
  repository already documents `main` as "the continuously auto-merged development branch"
  with "quality gated at the `release/*` QA window, not at merge time"; the per-unit
  pre-merge confirmation was the last thing still contradicting it. §6 was rewritten
  accordingly — the window's confirmation is no longer "a second confirmation that never
  weakens the first" but **the** confirmation, and skipping it removes the evidence rather
  than deferring it. **§1-4 was deliberately kept as a hard gate**: a plan whose
  verification line reads "none declared" is precisely the aspirational plan this mission
  exists to prevent, so a target with no method still halts.

- **Does this supersede the release-planning loop's boundary?** **Partly, and the part it
  supersedes is named.** FB `20260811010237` states the loop is "NOT a new agent role
  bolted onto `/ship`"; issue #438 instructs approximately that bolt-on, and the later
  instruction governs — so `/ship` does now draft. What is *not* superseded is that
  record's other claim, that §6's promotion confirmation "stays exactly the evidence-gated
  act it is": this change strengthens it into the sole production gate rather than
  weakening it. The division implemented is **`/ship` drafts per target, the release
  window confirms per batch** — the shape the ticket named as the alternative to merging
  the two. Whether the release-planning loop is additionally built remains the developer's
  scope call and is untouched here.

- **Which caller drafts, and does `/implement` still ship?** `/implement` still ships
  `auto` units, and `shipped` now means **merged with a current plan drafted**, not
  deployed. `drive/SKILL.md` §6 says so explicitly, and its gate table gains a row for a
  degraded plan read (report and skip; never half-write) while losing the row for a
  confirmation that ran and failed — an unattended run can no longer reach one.

### Discovered Insights

- **Insight**: the deploy-on-merge case is what makes "don't deploy on merge" only
  partially satisfiable by `/ship` alone, and the plan says so in the entry itself.
  **Context**: For `marketplace` the merge *is* the deployment; only the tag and published
  Release are separable. Rather than leave that contradiction to the reader, a
  deploy-on-merge entry carries an explicit line: what is pending is the release publish,
  not the commits. This is the one place a plan would otherwise read as actively wrong.

- **Insight**: the accepted-risk bypass and the non-overridable `secret` stop survive
  untouched, and that was worth checking rather than assuming.
  **Context**: The ticket predicted a refactor of this size is exactly where a hard gate
  gets quietly reclassified. Both were re-read after the edit: 2b's `overridable: false`
  row is unchanged in `SKILL.md` and in `reference/flow.md`, and the bypass moved from
  step 5 to step 4 by renumbering only, keeping its `"bypassed"` recording path.
