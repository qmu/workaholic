---
name: ship
description: Use when the user runs `/ship`, asks to "merge and deploy", "ship this branch", or "push to production". Pre-checks the workspace and todo queue, confirms with the user, merges the current branch's PR on GitHub, runs the deploy steps from CLAUDE.md's `## Deploy` section, and reports the outcome.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
metadata:
  internal: true
---

# Ship

Merge a pull request, deploy to production, and confirm the deployment actually succeeded in production. **Ship requires an established way to confirm the deployment, and the merge comes last**: deploy and production confirmation happen from the work branch *before* the PR is merged, and the merge is gated on a passing confirmation. A deployment that cannot be confirmed is not shippable. Standing rules, none optional:

- **Catching up with `main` is mandatory before any deploy step**, and reconciling with `main` is standard ship behavior — never an optional "your call". A branch behind `main` either reverts merged work or silently no-ops the release (a deploy-on-merge release is idempotent, so a colliding version ships nothing). A `mechanical` conflict — the version/lockstep manifests or regenerated `outputs/` — is reconciled as routine; only a genuinely ambiguous `content` conflict halts for a human.
- **Version-collision guard**: before deploying, confirm the branch's target version is greater than `main`'s and not an already-published tag; re-bump past a collision as part of reconciliation.
- **No confirmation method ⇒ halt** (§1-4): never silently skip, never merge. The one exception is the explicit accepted-risk bypass a developer consciously chooses, recorded into the story/PR — never silent, never the default. **A confirmation that ran and returned a failing result is never overridable**: the branch stays unmerged, and that is the rollback.

This skill is the worktree-independent ship essence: it operates on the current branch's PR. The `/ship` command resolves which claim to ship; `workaholic:drive` owns the claim lifecycle around it.

## Agent Compatibility

Works on any Agent-Skills-compatible agent; where a step uses `AskUserQuestion`, use the agent's native multiple-choice prompt. The confirmations are mandatory for an interactive caller; a caller that cannot prompt takes §0's routing instead of asking. Prefix each prompt's `question` body with `[<project label>]` (run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse its `project` value); leave the `header` as the decision label.

## 0. Unattended routing (when the caller cannot prompt)

`/ship` is called two ways: by a developer in a session, and by the unified `/drive` run for a PR-unit whose effective merge policy is `auto` (`workaholic:drive` §6) — a caller that cannot prompt at all. **This is a routing table over the existing seams, not a second flow**: every step runs exactly as written, and at each `AskUserQuestion` the unattended answer is the conservative one — stop, or hand the unit back to the PR path, never proceed on an assumption:

| Interactive seam | Unattended caller |
| ---------------- | ----------------- |
| §3 Workspace Guard, dirty tree | **Demote to PR.** Uncommitted work in the claim worktree is a finding, not a thing to ignore-and-proceed. |
| §4 Ticket Guard | Unchanged — already informational and non-blocking. |
| §1-3 confirm-before-deploy | **Proceed.** `merge_policy: auto`, recorded at creation, *is* that authorization. |
| §1-4 no confirmation method | **Demote to PR.** The accepted-risk bypass is a developer's conscious choice; an agent taking it is what "never the default" forbids. |
| Step 2 catch-up, `content` conflict | **Demote to PR.** (A `mechanical` conflict is routine reconciliation — unchanged.) |
| Step 2b scan, `overridable: true` (`size`/`leak`) | **Demote to PR.** An override is a human ruling. |
| Step 2b scan, `overridable: false` (`secret`) | **Hard stop**, exactly as interactively — non-overridable is non-overridable, and demoting it would launder a credential-bearing branch into "routine review". |
| Step 4 confirmation ran and **failed** | **Hard stop**, exactly as interactively. The unmerged branch is the rollback. |
| Step 7 release publish, no CI to defer to | **Skip and report** `release_pending`. Publishing is an outward action nobody authorized in this run. |

**Demote to PR** means: stop before the merge, leave the PR open and the branch pushed, and report the unit as demoted **with the gate that caused it**. **`auto` means no *approval* is needed; it never means no *gate* applies** — the tiers are identical, only the override path (which requires a human) is unavailable. `/ship` remains independently usable on a hand-driven branch with every prompt intact.

**Teardown belongs to the caller, not here.** After a successful merge, the unified run removes the claim worktree and branch (`workaholic:drive` §6). `/ship` may itself be running inside that worktree, and a merge that cleans up its own working directory cannot report its result. A worktree kept for a further batch is reset with `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reset-mission-worktree.sh <slug>`.

## 1. Deployment Contract

Ship learns how to deploy and how to confirm success from, in order of precedence: **`.workaholic/deployments/*.md`** (the structured contract — a `## Procedure` plus an executable `## Confirmation`, read via `read-deployments.sh`), then **`CLAUDE.md`'s `## Deploy` / `## Verify` sections** (via `find-claude-md.sh`). The confirmation method is mandatory: ship will not complete a deployment it cannot confirm. File formats and the two deploy models (*deploy-from-branch* / *deploy-on-merge*) are in [`reference/flow.md`](reference/flow.md) and `.workaholic/deployments/README.md`.

### 1-3. Confirm-before-deploy gate

Before executing the deploy procedure, display it and ask the user to confirm via AskUserQuestion. Declined ⇒ deployment skipped.

### 1-4. The hard gate (no confirmation method ⇒ halt, do not skip)

Runs pre-merge. A method exists when `read-deployments.sh` returns `has_confirmation: true` **or** `CLAUDE.md` has a non-empty `## Verify` section. If none: **HALT — do not deploy, do not merge, do not silently skip** — and ask the user (AskUserQuestion, command level) how to establish one: provide a verification path or transient credentials (never persisted anywhere), inspect production to derive and record a `.workaholic/deployments/` entry, author one and re-run, abort, or — deliberately — the accepted-risk bypass: merge without production confirmation, recorded into the story/PR before the merge (Ship Flow step 5's bypass path). The bypass is offered **only** for cannot-confirm cases (no method exists, or a declared method cannot execute in this environment); a confirmation that ran and failed is never bypassable. A docs-only project still states its trivial confirmation ("the merge is the deployment; confirm the commit is on `main`") rather than leaving it absent.

## 2. Shell Scripts

Full contracts — arguments, JSON envelopes, refusal reasons, and each rule's measured rationale — are [`reference/scripts.md`](reference/scripts.md). All run as `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/<name>.sh`:

| Script | One-line contract |
| ------ | ----------------- |
| `pre-check.sh "<branch>"` | PR number, URL, merge status for the branch |
| `catchup-main.sh "<base>"` | Fetch + merge `origin/<base>` into the work branch; resolves append-only `.workaholic/` conflicts itself; classes the rest `mechanical`/`content`; `merge_failed` means the merge never started |
| `read-deployments.sh` | `.workaholic/deployments/` contracts; `has_confirmation` drives §1-4 |
| `find-claude-md.sh` | Locates `./CLAUDE.md` |
| `check-confirmation-capability.sh "<method>"` | Can this environment run the method? Advisory only |
| `check-todo.sh` | Owned/unowned queued tickets; drives the §4 note only |
| `record-evidence.sh "<branch>" "<target>" "<method>" "<result>" "<status>"` | Appends `## Deployment Evidence` to the story; refuses `possible_secret` |
| `commit-release-note.sh "<branch>"` | Commits + pushes the release note; a failed push is a pre-merge hard stop (`release_note_not_on_remote`) |
| `merge-pr.sh "<pr-number>" [<base>]` | Merges; exit status reflects the merge only; read `commit_hash_source`/`on_base` before tagging |
| `publish-release.sh "<branch>" "<commit>" "<tag>" "<notes-file>"` | GitHub Release; defers to CI (`ci_publishes`); idempotent |
| `extract-deferred-concerns.sh "<branch>" "<pr>" "<url>" [<base>]` | Persists the story's Concerns into the feedback stream, append-only by `concern_id`; report `extracted`, `pushed`, `destination` |

## 3. Workspace Guard

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh`. On `clean: true`, proceed silently. Else display the `summary` and ask via AskUserQuestion: **"Ignore and proceed"** (the unrelated changes remain) or **"Stop"** (end the workflow immediately).

## 4. Ticket Guard (informational, non-blocking)

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh`. On `clean: false`, print **one** non-blocking note — "Note: N ticket(s) still queued in `.workaholic/tickets/todo/` (not blocking this ship): \<filenames\>" — and proceed anyway. Never prompt, never block, never move tickets: queued tickets are future work, unrelated to this branch's PR; shippability is gated by §3 and the deployment-confirmation gate, not the queue.

## 5. Ship Flow

Ship the current branch's PR. **Merge is the LAST step, gated on a passing production confirmation** — deploy and confirm happen from the work branch first, so an unconfirmable change never reaches `main`; a failed confirmation means the branch simply isn't merged (that is the rollback). Never merge first. Full per-step detail — JSON fields, failure branches, evidence and bypass invocations: [`reference/flow.md`](reference/flow.md).

1. **Pre-check** (`pre-check.sh`): no PR ⇒ "run `/report` first", stop; already merged ⇒ warn, proceed only to deploy/confirm/release. Capture `pr_number`/`url`.
2. **Catch up with `main`** (`catchup-main.sh`, mandatory) and apply the version-collision guard. `mechanical` ⇒ reconcile yourself as routine, no prompt; `content` ⇒ halt for the user; `merge_failed` ⇒ fix the working tree and re-run. Never present reconciliation as optional.
2b. **Branch-safety scan gate** (pre-merge, blocks like §1-4): `release-scan`'s `scan-branch-safety.sh | gate-decision.sh`. `overridable: false` (`secret`) ⇒ non-overridable hard stop, no bypass ever; `overridable: true` (`size`/`leak`) ⇒ fix and re-run, or the developer overrides with the accepted risk recorded via `record-evidence.sh … "bypassed"`.
3. **Deploy** (gated on §1-4, pre-merge): run the capability check (advisory), then execute the matching `## Procedure` / `## Deploy` after the §1-3 confirmation. For a deploy-on-merge project this step is the pre-merge readiness proof; the merge promotes.
4. **Confirm in production** (pre-merge): execute the captured confirmation method and capture the observed result. **A failing result is a failed ship — do NOT merge, not bypassable**; leave the PR open and stop. (Distinct from cannot-execute-at-all, which falls back to the §1-4 bypass option.)
5. **Record evidence and prepare merge artifacts** (pre-merge): `record-evidence.sh … "pass"` (or the bypass path with `"bypassed"`), generate the release note (`workaholic:write-release-note`, passing the PR `url`), commit both via `commit-release-note.sh` — a failed push is a pre-merge hard stop — and update the PR body (`report/scripts/create-or-update.sh`) so reviewers see the proof.
6. **Merge PR** (LAST): `merge-pr.sh`. On failure, inform and stop. Read `commit_hash_source` before using `commit_hash`; the post-merge base checkout is best-effort and never load-bearing (`checked_out` is a reported field, not a gate).
7. **Publish GitHub Release** (post-merge): `publish-release.sh` — defers to a CI release workflow; refuses to tag on `on_base: false` or `commit_hash_source: "branch_head"`.
8. **Extract deferred concerns** (post-merge): `extract-deferred-concerns.sh`, passing the base explicitly. Report `extracted`, `pushed` (best-effort by design, so read it — on `false`, a `git push` is outstanding) and `destination` (a record pushed off-base is invisible to `/report`'s judge and `/propose`).
9. **Summarize**: catch-up, scan result (with any recorded override), deploy and confirmation result (or — distinctly — the recorded accepted-risk bypass), merge status, release note, GitHub Release, concern extraction count with its `destination`, and `checked_out`/`checkout_reason` when the base was not checked out.

## 6. Release Promotion — the `release/*` staging tier

**A separate, explicitly-invoked phase over the base. Never a step of §5**, and `/drive` neither cuts nor confirms a release branch — if it were per-unit, every `auto` unit would open a release window. §5 lands one unit on the base; promotion takes the units already landed there to production. Mechanics, record schemas, and refusal envelopes: [`reference/release-tier.md`](reference/release-tier.md).

- **Flow**: cut the window (`branching/scripts/cut-release-branch.sh` — mints and pushes `release/YYYYMMDD-HHMMSS`, carries no commits of its own, never checked out; a refusal means no window exists), hold it open for QA, run the target's `## Confirmation` against its tip exactly as §5 step 4 runs it against a unit branch, then deploy/tag from the confirmed tip (`publish-release.sh`, still deferring to CI).
- **A promotion adds a second confirmation; it never weakens the first.** The per-unit confirmation proves one branch before it lands; this proves a batch already on the base. Inverting §5's evidence-before-merge rule is the one thing a promotion must not do.
- **A failed confirmation deletes nothing**: the release branch is the rollback boundary and the durable evidence of what was tried — record the failure (`confirm-release.sh … "fail"`) and cut a **fresh** branch for the next attempt; never re-point, force-push, or reuse one.
- **The durable record** is `.workaholic/releases/<release-branch>.md`, written on the base by `record-release-cut.sh` at the cut and `confirm-release.sh` at each attempt — derived from git, never hand-authored, with `since_reason` naming how the carried range was chosen.
- **No prompting anywhere**: every outcome is a reported JSON refusal or a recorded status; a decision the flow cannot make is a stop with its reason named, never a question.
