---
created_at: 2026-06-17T23:18:48+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure, Config]
effort: 2h
commit_hash: 0b564f4
category: Changed
depends_on:
---

# Reorder `/ship`: deploy and confirm in production BEFORE merging the PR

## Overview

The `/ship` Ship Flow **merges the PR first** (current step 3) and only reaches
the deploy + confirmation steps afterward (current steps 5–6). This defeats the
core design that the deployment-confirmation gate (commit
[80e721c](https://github.com/qmu/workaholic/commit/80e721c)) was built to
enforce: by the time the gate runs, the change is **already on `main`**. The
merge — the riskiest, least-reversible, outward-facing step — happens before we
know the deployment can even be confirmed.

This was proven the hard way dogfooding `/ship` on PR #47: the PR merged to
`main`, and *only then* did the gate discover there was no confirmation method
for this repo. "A deployment that cannot be confirmed is not shippable" is
meaningless if the merge precedes the check.

**Fix:** reorder the Ship Flow so deployment and production confirmation happen
**from the work branch, before the merge**, and the merge becomes the **final,
confirmation-gated** step. Concretely, the corrected order is:

1. Pre-check the PR exists and is open.
2. **Catch up with `main`** — merge/rebase the latest `main` into the work
   branch so the deploy reflects exactly what will land.
3. **Determine the deploy target** — which product/environment to deploy, from
   `.workaholic/deployments/` (preferred) or `CLAUDE.md ## Deploy`. If no
   confirmation method exists, the §1-4 hard gate **halts and asks here**
   (pre-merge), not after.
4. **Deploy** the product from the branch / its build artifact.
5. **Confirm in production** — execute the confirmation method and **capture the
   evidence** (the URL response, batch/command output, DB query result, etc.).
6. **Record the evidence** into the branch story and **update the PR** with it.
7. **Merge the PR** — only now, and only if confirmation passed.
8. **Update the release note** and publish the GitHub Release.

If confirmation **fails**, do **not** merge: the branch stays open and rollback
is trivial because nothing reached `main`. Record the failure on the branch.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - PRIMARY. The **Ship Flow** (§5) step order is the bug. Move `merge-pr.sh` (current step 3) to the end; move the §1-4 deployment-confirmation gate and the Deploy/Confirm steps (current 5–6) ahead of the merge; insert an "evidence capture + update story/PR" step between Confirm and Merge. The §1 Deployment Contract and §1-4 gate prose must say the gate runs **pre-merge**.
- `plugins/workaholic/commands/ship.md` - The routing prose and the "Deployment confirmation is required" paragraph should state that confirmation precedes merge.
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` - Now the last operation. Keep its behavior, but it must be invoked only after a passing confirmation; ensure it still syncs `main` afterward.
- `plugins/workaholic/skills/ship/scripts/extract-carryover.sh` - Currently runs right after merge (reads the merged story). Keep it post-merge, but note that the story is now updated with evidence *before* merge, so the merged story already carries it.
- `plugins/workaholic/skills/report/scripts/create-or-update.sh` - Reused mid-ship to push the evidence-updated story into the PR body before merge.
- `.workaholic/deployments/` - This repo needs its **own** deployment-target entry (currently only a README template exists) so `/ship` on workaholic has a real product/environment + confirmation method to exercise. Define what "deploying workaholic" means (e.g. publish the marketplace version / GitHub Release) and how to confirm it (e.g. the release tag is live and the plugin installs at the new version).
- `outputs/workflows/skills/ship/SKILL.md` - GENERATED; regenerate after the SKILL.md change (`node scripts/build-plugins/build.mjs`), CI-guarded.

## Related History

The deployment-confirmation gate this ticket repairs was added on the immediately preceding branch; the ordering flaw is the gap that branch's design left open.

Past tickets that touched similar areas:

- [20260617210615-require-verified-deployment-confirmation-in-ship.md](.workaholic/tickets/archive/work-20260617-210627/20260617210615-require-verified-deployment-confirmation-in-ship.md) - Added the hard confirmation gate but left it AFTER the merge in the Ship Flow; this ticket moves it before the merge so it can actually block an unconfirmable ship.
- [20260617210614-establish-deployments-directory-convention.md](.workaholic/tickets/archive/work-20260617-210627/20260617210614-establish-deployments-directory-convention.md) - The `.workaholic/deployments/` convention and `read-deployments.sh` reader the reordered flow consults pre-merge.
- [20260311121500-add-deployment-confirmation-to-ship-commands.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121500-add-deployment-confirmation-to-ship-commands.md) - Original confirm-before-deploy gate; this preserves that interaction but relocates the whole deploy/confirm phase ahead of merge.

## Implementation Steps

1. **Reorder Ship Flow (`SKILL.md` §5)** to: pre-check → catch up with `main` → evaluate deployment contract (§1-4 gate, pre-merge) → deploy → confirm in production (capture evidence) → record evidence in story + update PR → **merge** → release note → publish release → extract carry-overs → summarize.
2. **Add a "catch up with `main`" step**: merge (or rebase) `origin/main` into the work branch before deploying so the deployed artifact equals what will merge. Extract any conditional logic into a bundled script (no inline shell in markdown).
3. **Relocate the §1-4 hard gate to pre-merge**: when no confirmation method exists, halt and ask (provide verification path/credentials, inspect production, author a `.workaholic/deployments/` entry, or abort) *before* any merge — abort leaves `main` untouched.
4. **Add evidence capture**: after the confirmation executes, record its output as deployment evidence. Define where it lives — a new `## Deployment Evidence` block in `.workaholic/stories/<branch>.md` (date, target, method, command/URL, observed result, pass/fail) — and update the PR body via `create-or-update.sh` so reviewers see the proof before merge.
5. **Gate the merge on a passing confirmation**: `merge-pr.sh` runs only when confirmation passed. On failure, skip merge, leave the branch/PR open, and report — the "rollback" is simply not merging.
6. **Author this repo's own deployment contract**: add a `.workaholic/deployments/<target>.md` for workaholic describing what to deploy (marketplace version / GitHub Release for v-next) and the confirmation (release tag live + plugin installs at the new version), so `/ship` on workaholic exercises the real path instead of halting.
7. **Update `commands/ship.md`** prose to reflect merge-last ordering and pre-merge confirmation; keep it thin, all `AskUserQuestion` at command level.
8. **Regenerate `outputs/`** and run `node scripts/build-plugins/{build,verify,validate-metadata}.mjs` and `node scripts/test-workflow-scripts.mjs`; add/adjust a smoke test for any new ordering script.

## Considerations

- **operation:CI/CD policy** — deployment should move through automated stages with confirmation as a decision point, and rollback should be a real path, not a hope. Merging *after* a passing production confirmation makes "don't merge" the cleanest possible rollback (nothing reached `main` to revert), and recording the evidence in the story/PR satisfies "when and what was deployed" traceability (`plugins/workaholic/skills/operation/policies/ci-cd.md`).
- **implementation:Observability policy** — the confirmation is posterior verification; capturing its output as evidence and treating a failed confirmation as a rollback trigger (abort the merge) is the policy applied at ship time (`plugins/workaholic/skills/implementation/policies/observability.md`).
- **Deploy-from-branch tension** — some CD setups deploy *on* merge to `main` (merge is the trigger). For those, "deploy before merge" means deploying the branch to a **staging/preview** environment, confirming there, then merging to promote to production; document both models in the gate so the ordering is honest about what "production" means for each project. The user's intended flow is the branch-deploy-then-merge model.
- **Evidence integrity / secrets** — deployment evidence recorded in the story/PR must not embed credentials or secret tokens (the story is public on the PR); capture only non-secret observed results (status, version, hash, response body sans secrets) (`plugins/workaholic/skills/system-safety/SKILL.md`).
- **One-time reconciliation from the #47 incident** — PR #47 merged to `main` unconfirmed, and local `main` is currently ahead of `origin/main` by the post-merge `extract-carryover.sh` commit. As part of landing this, reconcile: decide whether to push that carry-over commit or fold it in, and confirm `origin/main` and local `main` match. This is cleanup from the bug, separate from the reorder itself.
- **Trip path** — keep the reordered flow in the portable `workaholic:ship` essence so the trip ship wrapper inherits merge-last ordering automatically (`plugins/workaholic/skills/ship/SKILL.md`).

## Final Report

Development completed as planned.

Reordered the `workaholic:ship` Ship Flow (§5) so the merge is the final step, gated on a passing production confirmation: pre-check → catch up with `main` → deploy + confirm (pre-merge, behind the §1-4 gate) → record evidence in the story and update the PR → merge → publish release → extract carry-overs → summarize. Updated the §1 intro and §1-4 gate prose to state the gate runs pre-merge and a failed/absent confirmation blocks the merge (not-merging is the rollback). Added two POSIX scripts — `catchup-main.sh` (fetch + merge `origin/<base>`, abort-and-report on conflict) and `record-evidence.sh` (append a non-secret `## Deployment Evidence` block to the story) — and documented them in §2. Authored this repo's own `.workaholic/deployments/marketplace.md` (deploy-on-merge target: pre-merge confirmation = build/verify/validate/test green + version aligned; post-merge = `gh release view` confirms the tag). Updated `commands/ship.md`. Added 5 hermetic smoke tests (record-evidence ×3, catchup-main ×2 using a temp bare origin); suite at 58/0. Regenerated `outputs/`.

### Discovered Insights

- **Insight**: Referencing the report skill's `create-or-update.sh` from `ship/SKILL.md` (to update the PR body mid-ship) made the build's cross-skill closure detector copy report's scripts into `outputs/workflows/skills/ship/report/`. This is the `${SCRIPT_DIR}` cross-skill closure mechanism (carry-over concern #42) working as designed; `verify.mjs` confirmed the bundle stays self-contained.
  **Context**: Any ship step that calls another skill's script pulls that skill's closure into ship's generated bundle. Keep cross-skill references in the full `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/...` form so the detector resolves them, and always re-run `verify.mjs` after adding one.
- **Insight**: "Confirm before merge" does not fit a deploy-on-merge target uniformly — for workaholic the release is published *from* the merge commit, which doesn't exist pre-merge. The flow resolves this by splitting confirmation: a pre-merge branch/staging proof (the verification suite + version alignment) gates the merge, and a post-merge release-tag check confirms the production promotion.
  **Context**: The deployments entry's `## Confirmation` is therefore written in two parts (pre-merge / post-merge). Projects that deploy a running service from a branch can confirm fully pre-merge; deploy-on-merge projects confirm readiness pre-merge and promotion post-merge.
