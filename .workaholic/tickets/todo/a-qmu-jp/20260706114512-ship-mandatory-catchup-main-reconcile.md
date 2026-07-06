---
created_at: 2026-07-06T11:45:12+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Ship: make catch-up with main mandatory and reconciliation standard, not a punted decision

## Overview

`/ship` already runs `catchup-main.sh` as Ship Flow step 2 (pre-deploy) — but the framing is too weak in two ways, and one script behavior actively fights the intended behavior:

1. **Catch-up is under-stated.** The skill should say **unambiguously that no deploy action may happen before the branch is reconciled with `main`**. A branch that is behind `main` and deploys anyway either (a) reverts merged work — a *deploy-from-branch* target pushes stale code over newer `main` work — or (b) **silently no-ops the release** — a *deploy-on-merge* target's release is idempotent, so if the branch's version is already taken on `main` the colliding merge produces a no-op release and ships nothing. Both are silent, outward-facing failures. Catching up with `main` before the deployment is not optional and is not the developer's call; it is what ship always does.

2. **Reconciliation is framed as a punted decision.** Today, on any conflict `catchup-main.sh` returns `{conflict:true}` and the skill says "halt and ask the user to resolve." That is right *only* for a genuinely ambiguous **content** conflict a human must judge. When catch-up surfaces a **mechanical** conflict — the version/lockstep manifests (`marketplace.json`, the two `plugin.json`s) or regenerated `outputs/` — reconciling is routine ship hygiene the agent performs itself: merge `origin/main`, resolve the mechanical conflict, re-run the pre-merge proof (build/verify/tests), and **re-bump the version past the collision** to the next free version. It must never be offered to the developer as "should I reconcile at all?"

3. **The version-collision guard is unencoded.** That `main` may have already reached/released the intended version (so the target must move to the next free version) is currently ad-hoc developer knowledge (seen manually applied on `work-20260626-124322`: 1.0.64→1.0.65, and `work-20260701-221800`: 1.0.76→1.0.79). Fold it explicitly into the catch-up step, because deploy-on-merge is idempotent and a colliding merge silently goes unreleased.

Chosen scope (developer-confirmed): **prose reframe of `ship/SKILL.md` + a `catchup-main.sh` enhancement** that surfaces the conflicted files and classifies them **mechanical vs content**, so the halt rule is deterministic (all-mechanical → agent reconciles as routine; any content conflict → halt-and-ask), backed by a **hermetic smoke test**. Regenerate `outputs/` (ship is a build target).

The motivation is deliberately generic — no specific external repository, service, or deployment. The failure modes (stale-branch deploy reverts merged work; colliding idempotent release silently goes unreleased) are described abstractly.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the shell-script principle: the mechanical-vs-content **classification logic must live in `catchup-main.sh`**, never as inline conditional git in SKILL.md prose. POSIX `#!/bin/sh -eu` (Alpine has no bash).
- `workaholic:operation` / `policies/ci-cd.md` — ship is the delivery/release automation path; the catch-up-before-deploy gate and the deploy-on-merge idempotency rationale are release-pipeline concerns; the change must keep the merge-last, confirm-before-merge ordering intact.
- `workaholic:implementation` / `policies/operational-planning.md` — ship is a recovery/continuity procedure worked backward from failure scenarios; "stale branch silently reverts/​no-ops" is exactly such a scenario, and catch-up is the guard. Keep it simple.
- `workaholic:implementation` / `policies/objective-documentation.md` — the reframed SKILL prose is documentation for a future agent: verifiable, imperative rules ("no deploy before catch-up"; "all-mechanical → agent reconciles; any content conflict → halt"), never aspirational.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` — **primary edit.** (a) Core-design paragraph (~line 14): add that reconciling with `main` is standard pre-deploy behavior. (b) §2-5b "Catch Up With main" (~lines 161-167): reframe as mandatory; document the new `catchup-main.sh` output (`conflicted_files`, mechanical/content classification) and the resolve-vs-halt rule; fold in the version-collision guard. (c) Ship Flow §5 step 2 (~line 220): change "halt and ask the user to resolve the conflict" → the agent reconciles mechanical conflicts (merge/resolve/re-run pre-merge proof/re-bump past collision) as routine; halt-and-ask ONLY on an ambiguous content conflict. (d) §1-4 idempotency note (~line 87) and step 3 Deploy (~lines 221-223): cross-reference that the deployed artifact already equals `main` post-catch-up and that version re-bump is part of the gate.
- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — **edit.** Today it `git merge --abort`s on any conflict and returns bare `{caught_up:false, conflict:true}`, discarding the conflict state. Change it to surface `conflicted_files` (from `git diff --name-only --diff-filter=U`) and a `conflict_class` of `mechanical` (every conflicted path is a version/lockstep manifest — `.claude-plugin/marketplace.json`, `plugins/workaholic/.claude-plugin/plugin.json`, `plugins/workaholic/.codex-plugin/plugin.json` — or under `outputs/`) vs `content` (any other path). Keep it POSIX `#!/bin/sh -eu`. Decide deliberately whether it still auto-aborts (returning classification for the agent to act on) or leaves the merge in progress; either way the JSON must give the SKILL prose a deterministic branch without inline git. Preserve the existing `{caught_up:true, already_current}` success shape.
- `scripts/test-workflow-scripts.mjs` — **edit.** Add a hermetic smoke test: build a throwaway repo, create a base-branch commit that conflicts on a version manifest (→ `mechanical`) and one that conflicts on a content file (→ `content`), run `catchup-main.sh`, assert the JSON shape (`conflicted_files`, `conflict_class`) and the clean-merge/no-op paths. No network, no `gh`.
- `outputs/workflows/skills/ship/SKILL.md` and `outputs/workflows/skills/ship/ship/scripts/catchup-main.sh` — **regenerated, not hand-edited.** `ship` is in `build.mjs` `DEFAULT_TARGETS`; run `node scripts/build-plugins/build.mjs` after the source edits.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md`, `.workaholic/deployments/README.md`, `.workaholic/deployments/marketplace.md` — **check only.** None describes the catch-up/reconcile behavior or version-collision guard, and "merge last" is unchanged, so all stay truthful (re-verify at implementation time). `marketplace.md`'s pre-merge confirmation already asserts version-consistency across lockstep files, which the re-bump satisfies.

## Related History

The catch-up-before-deploy mechanism this ticket hardens already exists; the scope is to elevate it to emphatically-mandatory standard behavior and fold in version reconciliation. The manual reconcile+re-bump ritual has already appeared on two shipped branches, which is the evidence that it should be encoded, not left ad-hoc.

Past work that shaped this area:

- [work-20260617-231848.md](.workaholic/stories/work-20260617-231848.md) - Reordered `/ship` so the merge is last (confirm-before-merge) and **introduced `catchup-main.sh` + the Catch Up With main step** — the foundation this ticket extends.
- [work-20260617-210627.md](.workaholic/stories/work-20260617-210627.md) - Established the `.workaholic/deployments/` convention and the hard confirmation gate the reorder builds on.
- [work-20260623-181237.md](.workaholic/stories/work-20260623-181237.md) - Added the pre-deploy confirmation-capability check and the deploy-on-merge vs deploy-from-branch distinction this ticket's collision guard interacts with.
- [work-20260626-124322.md](.workaholic/stories/work-20260626-124322.md) - Deployment Evidence records a manual "merged main, re-bumped 1.0.64→1.0.65 to avoid collision" — the ritual to automate.
- [work-20260701-221800.md](.workaholic/stories/work-20260701-221800.md) - Same ritual again (1.0.76→1.0.79 after standards-sync merges), recorded in its section-8 note.

## Implementation Steps

1. **Enhance `catchup-main.sh`** (POSIX `#!/bin/sh -eu`). On merge conflict, before deciding, capture `conflicted_files` via `git diff --name-only --diff-filter=U`. Classify: `mechanical` if every conflicted path is one of the three version/lockstep manifests or is under `outputs/`; else `content`. Emit `{caught_up:false, base, conflict:true, conflict_class:"mechanical"|"content", conflicted_files:[...]}`. Keep the `{caught_up:true, ..., already_current}` success shapes unchanged. Decide and document whether the merge is left in progress or aborted (if aborted, the agent re-runs the merge to resolve; if left in progress, the SKILL must say so) — pick the option that keeps the SKILL prose free of inline conditional git.
2. **Add the hermetic smoke test** to `scripts/test-workflow-scripts.mjs`: throwaway repo; assert (a) clean catch-up → `caught_up:true`; (b) no-op → `already_current:true`; (c) manifest conflict → `conflict_class:"mechanical"` with the manifest in `conflicted_files`; (d) content-file conflict → `conflict_class:"content"`. Follow the existing hermetic-test harness patterns; no network/`gh`.
3. **Reframe `ship/SKILL.md` prose** per Key Files (a)-(d): mandatory catch-up before any deploy; agent reconciles mechanical conflicts (merge → resolve → re-run pre-merge proof → re-bump version to next free past any collision) as routine; halt-and-ask ONLY on `conflict_class:"content"`; version-collision guard folded into catch-up; cross-references in §1-4 and step 3. Hold the prose to `objective-documentation` (imperative, verifiable rules).
4. **Regenerate outputs**: `node scripts/build-plugins/build.mjs`, then confirm `git status --porcelain outputs/` shows only the expected ship SKILL/script regeneration.
5. **Doc-truthfulness pass**: re-read `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md`, `.workaholic/deployments/README.md`, `.workaholic/deployments/marketplace.md`; confirm each stays truthful (expected: no edits — "merge last" unchanged). Update any that now under-describes the flow.
6. **Verify**: `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs` all green.

## Quality Gate

Prose + shell-script + test change to the ship delivery path; gated on structural presence, a green script smoke test, and a fresh build, with editorial approval at `/drive`.

**Acceptance criteria** — the checkable conditions that must hold:

- `ship/SKILL.md` states, as imperative rules: (a) **no deploy action before the branch is reconciled with `main`**; (b) the agent **reconciles mechanical version/lockstep/`outputs/` conflicts as routine** (merge → resolve → re-run pre-merge proof → re-bump past collision); (c) **halt-and-ask ONLY on an ambiguous content conflict**; (d) the **version-collision guard** (main hasn't already reached/released the target; deploy-on-merge is idempotent) is part of catch-up.
- `catchup-main.sh` returns `conflict_class` (`mechanical`/`content`) and `conflicted_files` on conflict, preserves the existing success shapes, and is POSIX `#!/bin/sh -eu` (passes the repo's posix-lint).
- The new hermetic smoke test asserts all four cases (clean, no-op, mechanical-conflict, content-conflict) and is green.
- The mechanical-vs-content classification lives in the **script**, not as inline conditional git in SKILL.md prose.
- The motivation names **no** specific external repository/service/deployment.
- Every check-only doc re-verified truthful.

**Verification method** — the commands/tests/reads that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including the new catchup-main assertions (count increases from 268).
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` shows only the expected ship regeneration; `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` green.
- Read back the edited `ship/SKILL.md` §14/§2-5b/§5-step-2/§1-4 and confirm each acceptance rule by inspection.
- `grep -n '#!/bin/sh' plugins/workaholic/skills/ship/scripts/catchup-main.sh` confirms the POSIX shebang.

**Gate** — what must pass before approval:

- Full smoke suite (incl. new tests) green; build regenerated with only-expected `outputs/` diff; verify + validate green; classification in the script (not prose); motivation generic; check-only docs confirmed truthful; developer reads the final SKILL prose at the `/drive` approval prompt.

## Considerations

- **Do not disturb "merge last".** The reorder that made merge the final, confirmation-gated step is load-bearing; catch-up is strictly *pre-deploy* and this change must not move the merge earlier (`plugins/workaholic/skills/ship/SKILL.md` §5, `.workaholic/deployments/README.md` Deploy models).
- **Classification boundary is the correctness risk.** Misclassifying a content conflict as mechanical would let the agent auto-resolve something a human should judge. Keep `mechanical` a *strict allowlist* (the three named manifests + `outputs/`); anything else is `content` → halt (`plugins/workaholic/skills/ship/scripts/catchup-main.sh`).
- **Shell-script principle.** The conflict classification is exactly the kind of conditional logic that must live in the script, not in SKILL prose (`plugins/workaholic/skills/implementation/policies/command-scripts.md`); POSIX `sh`, not bash.
- **outputs/ lockstep.** `ship` is a build target, so the source edit and its regenerated `outputs/workflows/skills/ship/` copies must land in the same change or the Outputs Freshness CI fails (`scripts/build-plugins/build.mjs`).
- **Keep it generic and portable.** The rule is about *any* deploy-from-branch or deploy-on-merge target, not this repo's marketplace specifically; phrase it so it reads correctly for a consumer project with its own `.workaholic/deployments/` contract.
