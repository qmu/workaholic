---
name: ship
description: Use when the user runs `/ship`, asks to "merge and deploy", "ship this branch", or "push to production". Pre-checks the workspace and todo queue, confirms with the user, merges the current branch's PR on GitHub, runs the deploy steps from CLAUDE.md's `## Deploy` section, and reports the outcome.
allowed-tools: Bash, Read, Glob, Grep
---

# Ship

**Draft the deployment plan; deploy only when a developer instructs it.** `/ship`'s default outcome is a Release Note whose `## Deployment Plan` says, per deployment target, what is waiting to deploy and the verification that would be required — and a merged pull request. It does **not** start a deployment. The developer reads the drafted plan and instructs the deploy; that instructed deployment runs the target's procedure, confirms it, and records the method and the observed result back into the same note.

Standing rules, none optional:

- **A deployment is instructed, never inferred.** No invocation of `/ship` deploys on its own, and no unattended caller can reach the deploy step at all (§0). Merging is not an instruction to deploy; neither is `merge_policy: auto`.
- **Catching up with `main` is mandatory**, and reconciling with `main` is standard ship behavior — never an optional "your call". A branch behind `main` either reverts merged work or silently no-ops the release (a deploy-on-merge release is idempotent, so a colliding version ships nothing). A `mechanical` conflict — the version/lockstep manifests or regenerated `outputs/` — is reconciled as routine; only a genuinely ambiguous `content` conflict halts for a human.
- **Version-collision guard**: confirm the branch's target version is greater than `main`'s and not an already-published tag; re-bump past a collision as part of reconciliation.
- **No confirmation method ⇒ halt** (§1-4): never silently skip, never merge. This gate is *unchanged by the drafting change* and is the reason it survives: the plan's whole value is naming the verification a target requires, so a target that names none leaves a plan that cannot be checked. The one exception is the explicit accepted-risk bypass a developer consciously chooses, recorded into the story/PR — never silent, never the default.
- **A confirmation that ran and returned a failing result is never overridable.** For an instructed deployment that means the failure is recorded (`fail`) and nothing is promoted; the unpromoted state is the rollback.

**Where the production evidence now lives** (the invariant this role change moved, 2026-08-13, resolving the fork ticket `20260813123903-make-ship-draft-the-plan-instead-of-deploying` carried). `/ship` §5 used to deploy and confirm pre-merge and gate the merge on that confirmation, so an unconfirmable change never reached `main`. With `/ship` no longer deploying, **§5's merge is no longer gated on an executed production confirmation** — and the evidence is not dropped, it is relocated to the `release/*` QA window (§6), which already runs the target's `## Confirmation` against the window's tip and which the repository already documents as where quality is gated rather than at merge time. What still gates §5's merge: the branch-safety scan (2b, `secret` non-overridable), the mandatory catch-up, and the §1-4 requirement that a confirmation method *exist*. `main` is the continuously-merged development branch; production is `release/*`.

This skill is the worktree-independent ship essence: it operates on the current branch's PR. The `/ship` command resolves which claim to ship; `drive` owns the claim lifecycle around it.

## Agent Compatibility

Works on any Agent-Skills-compatible agent; where a step uses the agent's selection prompt, use the agent's native multiple-choice prompt. The confirmations are mandatory for an interactive caller; a caller that cannot prompt takes §0's routing instead of asking. Prefix each prompt's `question` body with `[<project label>]` (run `bash gather/scripts/project-label.sh` once and reuse its `project` value); leave the `header` as the decision label.

## 0. Unattended routing (when the caller cannot prompt)

`/ship` is called two ways: by a developer in a session, and by the unified `/drive` run for a PR-unit whose effective merge policy is `auto` (`drive` §6) — a caller that cannot prompt at all. **This is a routing table over the existing seams, not a second flow**: every step runs exactly as written, and at each the agent's selection prompt the unattended answer is the conservative one — stop, or hand the unit back to the PR path, never proceed on an assumption:

| Interactive seam | Unattended caller |
| ---------------- | ----------------- |
| §3 Workspace Guard, dirty tree | **Demote to PR.** Uncommitted work in the claim worktree is a finding, not a thing to ignore-and-proceed. |
| §4 Ticket Guard | Unchanged — already informational and non-blocking. |
| §1-3 the deploy instruction | **Never deploy. Draft the plan and report it.** There is no seam here an unattended caller can pass: a deployment needs a developer's instruction, and `merge_policy: auto` is authorization to *merge*, never to deploy. (Until 2026-08-13 this row read "Proceed", because `/ship` deployed pre-merge and `auto` carried that authorization; the role change removed the step, not just the prompt.) |
| §1-4 no confirmation method | **Demote to PR.** The accepted-risk bypass is a developer's conscious choice; an agent taking it is what "never the default" forbids. The gate is about the plan being checkable, so it still applies with nothing being deployed. |
| Step 2 catch-up, `content` conflict | **Demote to PR.** (A `mechanical` conflict is routine reconciliation — unchanged.) |
| Step 2b scan, `overridable: true` (`size`/`leak`) | **Demote to PR.** An override is a human ruling. |
| Step 2b scan, `overridable: false` (`secret`) | **Hard stop**, exactly as interactively — non-overridable is non-overridable, and demoting it would launder a credential-bearing branch into "routine review". |
| Step 3 drafting phase, degraded read | **Report and skip the plan; do not half-write it.** `draft-deploy-plan.sh` reports its `reason` and leaves the note untouched; the unit still routes on the gates above. |
| The instructed-deploy path (steps D1-D3) | **Unreachable.** An unattended caller has no instruction, so it never enters. A confirmation that ran and failed is a hard stop for whoever *did* instruct it. |
| Step 7 release publish, no CI to defer to | **Skip and report** `release_pending`. Publishing is an outward action nobody authorized in this run. |

**Demote to PR** means: stop before the merge, leave the PR open and the branch pushed, and report the unit as demoted **with the gate that caused it**. **`auto` means no *approval* is needed; it never means no *gate* applies** — the tiers are identical, only the override path (which requires a human) is unavailable. `/ship` remains independently usable on a hand-driven branch with every prompt intact.

**Teardown belongs to the caller, not here.** After a successful merge, the unified run removes the claim worktree and branch (`drive` §6). `/ship` may itself be running inside that worktree, and a merge that cleans up its own working directory cannot report its result. A worktree kept for a further batch is reset with `bash branching/scripts/reset-mission-worktree.sh <slug>`.

## 1. Deployment Contract

Ship learns how to deploy and how to confirm success from, in order of precedence: **`.workaholic/deployments/*.md`** (the structured contract — a `## Procedure` plus an executable `## Confirmation`, read via `read-deployments.sh`), then **`CLAUDE.md`'s `## Deploy` / `## Verify` sections** (via `find-claude-md.sh`). The confirmation method is mandatory: ship will not complete a deployment it cannot confirm, and will not draft a plan that names no verification. File formats and the two deploy models (*deploy-from-branch* / *deploy-on-merge*) are in [`reference/flow.md`](reference/flow.md) and `.workaholic/deployments/README.md`.

### 1-3. The deploy instruction

**There is no confirm-before-deploy prompt, because there is no deploy step to confirm.** Step 3 drafts the plan and reports it; the deploy path (steps D1-D3) runs **only** when the caller's invocation carries the developer's instruction to deploy a named target — an instruction the developer gives after reading the drafted plan. `/ship` still has exactly **one** behaviour: the instruction is not a subcommand and never the first word of an argument. Before executing an instructed procedure, display it and confirm via the agent's selection prompt; declined ⇒ deployment skipped, plan unchanged.

### 1-4. The hard gate (no confirmation method ⇒ halt, do not skip)

Runs pre-merge, and **survives the drafting change unchanged**: a plan whose verification line reads "none declared" is exactly the aspirational plan this mission exists to prevent. A method exists when `read-deployments.sh` returns `has_confirmation: true` **or** `CLAUDE.md` has a non-empty `## Verify` section. If none: **HALT — do not deploy, do not merge, do not silently skip** — and ask the user (the agent's selection prompt, command level) how to establish one: provide a verification path or transient credentials (never persisted anywhere), inspect production to derive and record a `.workaholic/deployments/` entry, author one and re-run, abort, or — deliberately — the accepted-risk bypass: merge without production confirmation, recorded into the story/PR before the merge (Ship Flow step 5's bypass path). The bypass is offered **only** for cannot-confirm cases (no method exists, or a declared method cannot execute in this environment); a confirmation that ran and failed is never bypassable. A docs-only project still states its trivial confirmation ("the merge is the deployment; confirm the commit is on `main`") rather than leaving it absent.

## 2. Shell Scripts

Full contracts — arguments, JSON envelopes, refusal reasons, and each rule's measured rationale — are [`reference/scripts.md`](reference/scripts.md). All run as `bash ship/scripts/<name>.sh`:

| Script | One-line contract |
| ------ | ----------------- |
| `pre-check.sh "<branch>"` | PR number, URL, merge status for the branch |
| `catchup-main.sh "<base>"` | Fetch + merge `origin/<base>` into the work branch; resolves append-only `.workaholic/` conflicts itself; classes the rest `mechanical`/`content`; `merge_failed` means the merge never started |
| `read-deployments.sh [--slugs \| --slug <s>]` | `.workaholic/deployments/` contracts; `has_confirmation` drives §1-4. The single-target modes exist so a composing script never re-parses a target record |
| `read-release-notes.sh [--latest-for <slug> [--exclude <p>]]` | The one parser for release-note frontmatter; reports a target join as `declared` or the weaker `recency` |
| `read-deploy-state.sh [--rows \| --base-rev] [--exclude-note <p>] [<base>]` | The plan consolidation: per target, its contract, its latest note, and the unreleased range with a named `since_reason` and `attribution`. Pure read |
| `draft-deploy-plan.sh <note-path> [<base>]` | Writes/refreshes the note's `## Deployment Plan`; idempotent (`changed: false` on an unchanged base), and writes nothing on a degraded read |
| `find-claude-md.sh` | Locates `./CLAUDE.md` |
| `check-confirmation-capability.sh "<method>"` | Can this environment run the method? Advisory only |
| `check-todo.sh` | Owned/unowned queued tickets; drives the §4 note only |
| `record-evidence.sh "<branch>" "<target>" "<method>" "<result>" "<status>" ["<note-path>"]` | Appends `## Deployment Evidence` to the story and, given a note, the matching append-only `## Deployment Verification` block; `pass`/`fail`/`not_run`/`bypassed`; refuses `possible_secret` before writing either |
| `commit-release-note.sh "<branch>"` | Commits + pushes the release note; a failed push is a pre-merge hard stop (`release_note_not_on_remote`) |
| `merge-pr.sh "<pr-number>" [<base>]` | Merges; exit status reflects the merge only; read `commit_hash_source`/`on_base` before tagging |
| `publish-release.sh "<branch>" "<commit>" "<tag>" "<notes-file>"` | GitHub Release; defers to CI (`ci_publishes`); idempotent |
| `extract-deferred-concerns.sh "<branch>" "<pr>" "<url>" [<base>]` | Persists the story's Concerns into the feedback stream, append-only by `concern_id`; report `extracted`, `pushed`, `destination` |

## 3. Workspace Guard

Run `bash branching/scripts/check-workspace.sh`. On `clean: true`, proceed silently. Else display the `summary` and ask via the agent's selection prompt: **"Ignore and proceed"** (the unrelated changes remain) or **"Stop"** (end the workflow immediately).

## 4. Ticket Guard (informational, non-blocking)

Run `bash ship/scripts/check-todo.sh`. On `clean: false`, print **one** non-blocking note — "Note: N ticket(s) still queued in `.workaholic/tickets/todo/` (not blocking this ship): \<filenames\>" — and proceed anyway. Never prompt, never block, never move tickets: queued tickets are future work, unrelated to this branch's PR; shippability is gated by §3 and the deployment-confirmation gate, not the queue.

## 5. Ship Flow

Ship the current branch's PR. **The flow's outcome is a drafted plan and a merged PR; it deploys nothing.** Full per-step detail — JSON fields, failure branches, evidence and bypass invocations: [`reference/flow.md`](reference/flow.md).

1. **Pre-check** (`pre-check.sh`): no PR ⇒ "run `/report` first", stop; already merged ⇒ warn, proceed to the drafting phase only. Capture `pr_number`/`url`.
2. **Catch up with `main`** (`catchup-main.sh`, mandatory) and apply the version-collision guard. `mechanical` ⇒ reconcile yourself as routine, no prompt; `content` ⇒ halt for the user; `merge_failed` ⇒ fix the working tree and re-run. Never present reconciliation as optional.
2b. **Branch-safety scan gate** (pre-merge, blocks like §1-4): `release-scan`'s `scan-branch-safety.sh | gate-decision.sh`. `overridable: false` (`secret`) ⇒ non-overridable hard stop, no bypass ever; `overridable: true` (`size`/`leak`) ⇒ fix and re-run, or the developer overrides with the accepted risk recorded via `record-evidence.sh … "bypassed"`.
3. **Draft the deployment plan** (the phase that replaced the deploy step): apply §1-4, then generate the release note (`write-release-note`, passing the PR `url`) and run `draft-deploy-plan.sh <note-path>` over it. Report the plan — per target, what is waiting and the verification required. A degraded read (`ok: false`) is **reported and skipped**, never half-written. Run the capability check (`check-confirmation-capability.sh`) for each target's method and report an incapable environment: the plan says the check *would* run there.
4. **Commit the merge artifacts** (pre-merge): `commit-release-note.sh` — a failed push is a pre-merge hard stop — then update the PR body (`report/scripts/create-or-update.sh`) so reviewers see the plan before the merge.
5. **Merge PR**: `merge-pr.sh`. On failure, inform and stop. Read `commit_hash_source` before using `commit_hash`; the post-merge base checkout is best-effort and never load-bearing (`checked_out` is a reported field, not a gate). The merge is **not** a deployment and grants no authorization to start one.
6. **Publish GitHub Release** (post-merge): `publish-release.sh` — defers to a CI release workflow; refuses to tag on `on_base: false` or `commit_hash_source: "branch_head"`.
7. **Extract deferred concerns** (post-merge): `extract-deferred-concerns.sh`, passing the base explicitly. Report `extracted`, `pushed` (best-effort by design, so read it — on `false`, a `git push` is outstanding) and `destination` (a record pushed off-base is invisible to `/report`'s judge and `/propose`).
8. **Summarize**: catch-up, scan result (with any recorded override), **the drafted plan and whether it changed**, merge status, release note, GitHub Release, concern extraction count with its `destination`, and `checked_out`/`checkout_reason` when the base was not checked out.

### 5-D. The instructed deployment

Runs **only** on a developer's instruction naming a target, and never in the same breath as the flow above — the plan is read first, then the deploy is asked for. An unattended caller never reaches this path (§0).

- **D1. Deploy**: run the capability check (advisory), display the target's `## Procedure` / `## Deploy`, confirm (§1-3), and execute.
- **D2. Confirm**: execute the target's `## Confirmation` / `## Verify` and capture the observed result. A failing result is a **failed deployment** — record it and promote nothing.
- **D3. Record**: `record-evidence.sh "<branch>" "<target>" "<method>" "<result>" "<status>" "<note-path>"` with the honest status — `pass`, `fail`, `not_run` (the environment cannot execute the declared method), or `bypassed`. It writes the story's `## Deployment Evidence` and the note's append-only `## Deployment Verification` from one call, so the plan and its answer sit in the same document.

## 6. Release Promotion — the `release/*` staging tier

**A separate, explicitly-invoked phase over the base. Never a step of §5**, and `/drive` neither cuts nor confirms a release branch — if it were per-unit, every `auto` unit would open a release window. §5 lands one unit on the base; promotion takes the units already landed there to production. Mechanics, record schemas, and refusal envelopes: [`reference/release-tier.md`](reference/release-tier.md).

- **This is where the production evidence lives** (since 2026-08-13). §5 no longer deploys, so the window's confirmation is not a *second* proof on top of a per-unit one — it is **the** proof, and the one thing a promotion must never do is skip it. Everything the per-unit confirmation used to guarantee is now guaranteed here, over a batch, or it is not guaranteed at all.
- **Flow**: cut the window (`branching/scripts/cut-release-branch.sh` — mints and pushes `release/YYYYMMDD-HHMMSS`, carries no commits of its own, never checked out; a refusal means no window exists), hold it open for QA, run the target's `## Confirmation` against its tip, then deploy/tag from the confirmed tip (`publish-release.sh`, still deferring to CI).
- **A failed confirmation deletes nothing**: the release branch is the rollback boundary and the durable evidence of what was tried — record the failure (`confirm-release.sh … "fail"`) and cut a **fresh** branch for the next attempt; never re-point, force-push, or reuse one.
- **The durable record** is `.workaholic/releases/<release-branch>.md`, written on the base by `record-release-cut.sh` at the cut and `confirm-release.sh` at each attempt — derived from git, never hand-authored, with `since_reason` naming how the carried range was chosen.
- **No prompting anywhere**: every outcome is a reported JSON refusal or a recorded status; a decision the flow cannot make is a stop with its reason named, never a question.
