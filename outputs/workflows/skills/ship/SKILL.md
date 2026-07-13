---
name: ship
description: Use when the user runs `/ship`, asks to "merge and deploy", "ship this branch", or "push to production". Pre-checks the workspace and todo queue, confirms with the user, merges the current branch's PR on GitHub, runs the deploy steps from CLAUDE.md's `## Deploy` section, and reports the outcome.
allowed-tools: Bash, Read, Glob, Grep
---

# Ship

Merge a pull request, deploy to production, and **confirm the deployment actually succeeded in production**. The agent acts as the deployment agent, following the deployment procedure and — critically — the success-confirmation method declared for the target.

**Core design: ship requires an established way to confirm the deployment, and the merge comes last.** A deployment that cannot be confirmed is not shippable. Deploy and production confirmation happen from the work branch **before** the PR is merged; the merge is the final step, gated on a passing confirmation.

**Catching up with `main` is mandatory before any deploy step, and reconciling with `main` is standard ship behavior — never an optional "your call."** A branch that is behind `main` and deploys anyway either reverts merged work (a deploy-from-branch target pushes stale code over newer `main`) or **silently no-ops the release** (a deploy-on-merge release is idempotent, so if the branch's version is already taken on `main` the colliding merge ships nothing). So ship *always* catches up first (Ship Flow step 2), and when catch-up surfaces a **mechanical** conflict — the version/lockstep manifests or regenerated `outputs/` — the agent **reconciles it as routine**: merge `origin/main`, resolve the manifests, re-run the pre-merge proof, and re-bump the version past the collision. Only a genuinely ambiguous **content** conflict a human must judge is a halt-and-ask. The agent does not ask "should I reconcile with `main` at all?" — reconciliation is what ship does. If no documented confirmation method exists (neither a `.workaholic/deployments/` entry nor a `CLAUDE.md` `## Verify` section), ship does **not** silently skip and does **not** merge — it **halts** and asks the user to provide a verification path or credentials to confirm the change reached production, or to author a `.workaholic/deployments/` entry. The confirmation is **executed** and its evidence recorded into the story/PR before merge; a failed confirmation is a failed ship and the branch stays unmerged (that is the rollback). The one deliberate exception is an **explicit, recorded override**: when a confirmation method cannot be established or executed at all, the developer may consciously choose to merge without production confirmation — that choice is recorded into the story/PR as an accepted-risk, production-unverified merge (never silent, never the default). A confirmation that *ran and returned a failing result* is never overridable this way.

This skill is the **trip-independent ship essence**: it operates on the current branch's PR. Worktree handling and drive/trip context routing are not part of this skill — in Claude Code they are handled separately by the trip workflow and the `/ship` command. Any agent can run this skill directly to ship the current branch.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses the agent's selection prompt (workspace/ticket guards, deploy confirmation, the §1-4 no-confirmation-method halt), use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The confirmations are mandatory; only the prompt mechanism varies. (This skill has no subagent fan-out.) Prefix each interactive prompt's (the agent's selection prompt) `question` body with `[<project label>]` — run `bash gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## 1. Deployment Contract

Ship learns **how to deploy** and **how to confirm success** from two sources, in this order of precedence for the confirmation method:

1. **`.workaholic/deployments/*.md`** — the structured deployment contract (see the `deployments/` convention in `workaholic` rules). Each file declares a target's `## Procedure` and an executable `## Confirmation` method, read via `read-deployments.sh`. This is the preferred source.
2. **`CLAUDE.md` `## Deploy` / `## Verify` sections** — the project's instructions file, located via `find-claude-md.sh`. Used when there is no `.workaholic/deployments/` entry (or as a supplement).

The **confirmation method** (a `.workaholic/deployments/` `## Confirmation`, or a `CLAUDE.md` `## Verify`) is mandatory: ship will not complete a deployment it cannot confirm.

### 1-1. Search Order

```bash
bash ship/scripts/read-deployments.sh
bash ship/scripts/find-claude-md.sh
```

`read-deployments.sh` searches `.workaholic/deployments/`; `find-claude-md.sh` searches `./CLAUDE.md`.

### 1-2. Expected Content

A `.workaholic/deployments/<target>.md` entry:

```markdown
---
title: ...
environment: production
confirmation_method: browser   # browser | server-batch | db-query | api-probe | other
url: ...                       # optional, non-secret locator
---
## Procedure
Step-by-step deployment instructions for the agent to execute.
## Confirmation
The exact, executable way to confirm the deploy succeeded in production.
```

Or, in `CLAUDE.md`:

```markdown
## Deploy
Step-by-step deployment instructions for the agent to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

### 1-3. Confirm-before-deploy gate

Before executing the deploy procedure, display it and ask the user to confirm via the agent's selection prompt. If the user declines, deployment is skipped.

### 1-4. The hard gate (no confirmation method ⇒ halt, do not skip)

This gate runs **pre-merge** (Ship Flow step 3), so a failed or impossible confirmation blocks the merge instead of discovering the problem after the change is already on `main`.

Determine whether an established confirmation method exists: `read-deployments.sh` returns `has_confirmation: true`, **or** `CLAUDE.md` has a non-empty `## Verify` section.

- **If a confirmation method exists** — proceed: run the confirm-before-deploy gate (§1-3), deploy, then **execute** the confirmation (§5 step 4), record the evidence, and only then merge.
- **If no confirmation method exists** — **HALT. Do not deploy, do not merge, do not silently skip.** Ask the user (via the agent's selection prompt, at the command/main-agent level) how to establish confirmation. Options:
  - **Provide a verification path / credentials now** — the user supplies the URL, command, or transient credentials to sign into the production web system or server so the change can be confirmed. (Credentials are used transiently — never written to `.workaholic/deployments/*.md`, shell profiles, or global config.)
  - **Inspect production first** — ship inspects the production web system (e.g. via browser tooling) to determine how the deploy can be assured, then records it as a `.workaholic/deployments/` entry.
  - **Author a `.workaholic/deployments/` entry** — pause so the user (or the agent) writes the contract, then re-run.
  - **Abort the ship** — stop without deploying.
  - **Merge without production confirmation (accepted-risk bypass)** — proceed to the merge despite no confirmable production proof. Offered **only** for the cannot-confirm cases (no method exists, or a declared method cannot execute in this ship environment); a confirmation that *ran and failed* is never bypassable. The choice is explicit and is **recorded** into the story/PR as an accepted-risk, production-unverified merge before the merge runs (Ship Flow §5 step 5, bypass path) — never silent, never the default.

A docs/config-only project legitimately may have a trivial confirmation (e.g. "the merge to `main` is the deployment; confirm the commit is on `main`"); that still must be stated as a confirmation method, not left absent.

A target follows one of two **deploy models** — *deploy-from-branch* (deploy + confirm from the branch, then merge) or *deploy-on-merge* (the merge is the deployment; confirmation splits into a pre-merge readiness proof and a post-merge promotion check). The `.workaholic/deployments/README.md` "Deploy models" section spells out both with copyable examples; a deploy-on-merge target should label its `## Confirmation` pre-merge vs post-merge so the two phases are unambiguous.

## 2. Shell Scripts

### 2-1. Pre-check

```bash
bash ship/scripts/pre-check.sh "<branch>"
```

Verifies a PR exists for the branch. Returns JSON with PR number, URL, and merge status.

### 2-2. Merge PR

```bash
bash ship/scripts/merge-pr.sh "<pr-number>"
```

Merges the PR, checks out main, and pulls to sync. Returns JSON with merge status and commit hash.

### 2-3. Find CLAUDE.md

```bash
bash ship/scripts/find-claude-md.sh
```

Searches for the project's `CLAUDE.md`. Returns JSON with path or `{"found": false}`.

### 2-3b. Read Deployment Contract

```bash
bash ship/scripts/read-deployments.sh
```

Reads `.workaholic/deployments/*.md`. Returns `{"has_confirmation": <bool>, "count": N, "deployments": [{title, environment, confirmation_method, url, endpoint, command, procedure, confirmation}]}`. `has_confirmation` is true iff at least one target declares a `confirmation_method` and a non-empty `## Confirmation` body. Drives the §1-4 hard gate. Returns the empty/no-confirmation result (never errors) when the directory is absent.

### 2-3c. Check Confirmation Capability

```bash
bash ship/scripts/check-confirmation-capability.sh "<confirmation_method>"
```

Checks whether the current ship environment has the tooling the matched target's `confirmation_method` needs (`api-probe` → curl/wget; `db-query` → a DB client; `server-batch` → ssh; `browser` → an interactive agent, flagged in CI). Returns `{"method", "capable": <bool>, "missing", "hint"}`. **Advisory only** — it warns and steers toward a headless-executable method; it never blocks on its own (the §1-4 gate and the actual confirmation in §5 step 4 remain authoritative). Run it pre-deploy (Ship Flow step 3).

### 2-4. Check Todo

```bash
bash ship/scripts/check-todo.sh
```

Checks if the current user's `.workaholic/tickets/todo/<user>/` queue has remaining tickets. Returns JSON with cleanliness status, count, and ticket list. Drives the **informational, non-blocking** §4 note — it reports the count, but the queued tickets never block the merge (they are future work, unrelated to this branch's PR). The check is scoped to the current user's subdirectory: other developers' tickets (in their own subdirectories, or unswept at the `todo/` root) are never counted.

### 2-4b. Commit Release Note

```bash
bash ship/scripts/commit-release-note.sh "<branch>"
```

Stages, commits (`Add release notes for <branch>`), and pushes any note file(s) under `.workaholic/release-notes/` so they ride into the merge. Returns `{committed, branch}` or `{committed:false, reason:"no_release_note_changes"}`. Run after `write-release-note` has written the note and before `merge-pr.sh`.

### 2-5. Extract Deferred Concerns

```bash
bash ship/scripts/extract-deferred-concerns.sh "<branch>" "<pr-number>" "<pr-url>"
```

Reads the just-shipped story (`.workaholic/stories/<branch>.md`) and parses each `###` concern block in section 6 (Concerns). Each concern is keyed on a **stable identity** — `concern_id`, the slug of its title with any leading `(carried from …)` prefix stripped — so the same logical concern is recognized across PRs. Extraction is **update-or-create**, not append:

- an **active** concern with that id → **updated in place** (bumps `last_seen`, escalates `severity` to the most severe, refreshes text) — no new file;
- an **archived** (resolved/superseded) one → skipped (never resurfaces);
- otherwise → a fresh `<concern_id>.md` is written (`type: Concern`, `concern_id`, `first_seen`, `last_seen`, `severity`, provenance, and a Title/Description/How-to-Fix body).

This is what keeps the corpus **fresh** instead of accumulating `NN-carried-from-…` clones. Before parsing, it runs the living identity migration (`report/scripts/migrate-concern-identity.sh`, best-effort, idempotent), which back-fills identity fields on legacy files and collapses existing carry chains into one file per concern. Returns JSON:

```json
{"status":"ok","created":2,"updated":8,"extracted":2,"files":["..."]}
```

`extracted` counts **new** files (`created`); `updated` counts in-place refreshes; `files` lists the newly-created files. Commits with message `Add deferred concerns from PR #<pr-number>` (whenever anything was created or updated) so the corpus stays under version control, then **pushes**. Because this runs post-merge, the commit lands on local `main` (the merge already checked it out); the push keeps local `main` level with `origin/main`. Skips silently when no story file exists or section 6 is empty.

### 2-5b. Catch Up With main

```bash
bash ship/scripts/catchup-main.sh "<base-branch>"
```

Fetches origin and merges `origin/<base>` (default `main`) into the current work branch so the artifact that gets deployed and confirmed equals what will land on merge. This step is **mandatory before any deploy step** — never skip it. Returns:

- `{caught_up:true, already_current:bool}` — merged cleanly (or already current). Proceed.
- `{caught_up:false, conflict:true, conflict_class:"mechanical", conflicted_files:[...]}` — every conflict is a version/lockstep manifest (`.claude-plugin/marketplace.json`, either `plugin.json`) or under `outputs/`. **The agent reconciles this itself, as routine ship hygiene — do not ask the developer whether to reconcile.** Merge `origin/main`, resolve the manifest conflicts (take `main`'s side of the version, then re-bump to the next free version), regenerate `outputs/` (`node scripts/build-plugins/build.mjs`), re-run the pre-merge proof (build/verify/tests), and continue. This is the same reconcile-and-re-bump the version-collision guard requires (see below).
- `{caught_up:false, conflict:true, conflict_class:"content", conflicted_files:[...]}` — a non-manifest path conflicts and needs human judgment. **Halt the Ship Flow and ask the developer to resolve it** before continuing.

**Version-collision guard (fold into this step).** Deploy-on-merge releases are idempotent, so a merge at a version already reached/released on `main` silently goes unreleased. Before deploying, confirm the branch's target version is **greater than** `main`'s current version and is not an already-published tag; if not (which a mechanical catch-up conflict on the manifests reveals), re-bump to the next free version as part of reconciliation. Run this step **before** the deploy gate.

### 2-5c. Record Deployment Evidence

```bash
bash ship/scripts/record-evidence.sh "<branch>" "<target>" "<method>" "<result>" "<status>"
```

Appends a `## Deployment Evidence` block (when / target / method / status / observed result) to `.workaholic/stories/<branch>.md` so the proof of a successful production confirmation rides into the merge and shows on the PR. `<result>` must be a **non-secret** observed result; `<status>` is `pass`|`fail`. Run after the confirmation executes and **before** the merge. The script **scans the inputs for common secret shapes** (cloud keys, GitHub/Slack tokens, bearer/basic auth, PEM keys, `password=`/`token=` assignments) and **refuses** (`{"recorded": false, "reason": "possible_secret"}`, non-zero exit) rather than writing a credential into the public story — re-supply a sanitized result if it refuses.

### 2-6. Publish GitHub Release

```bash
bash ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"
```

Publishes a GitHub Release from the generated note **unless** the repo already has a GitHub Actions workflow that publishes releases (scans `.github/workflows/` for `gh release create` / `softprops/action-gh-release` / `actions/create-release`). Returns `{published:false, reason:"ci_publishes"}` when CI owns publishing, `{published:false, reason:"no_notes_file"|"already_exists"}` for the safe no-ops, or `{published:true, tag, url, reason:"created"}`. Idempotent: never errors on an existing tag. Targets the merge commit.

## 3. Workspace Guard

```bash
bash branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ticket Guard.

If `clean` is `false`, display the `summary` to the user and ask via the agent's selection prompt with selectable options:
- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the workflow so you can handle the changes first.

If the user selects "Stop", end the workflow immediately.

## 4. Ticket Guard (informational, non-blocking)

```bash
bash ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ship Flow.

If `clean` is `false`, print **one** non-blocking note and **proceed to the Ship Flow anyway** — never prompt, never block, never move tickets:

> Note: N ticket(s) still queued in your `.workaholic/tickets/todo/<user>/` (not blocking this ship): \<filenames\>.

The queued tickets are future/unstarted work, unrelated to this branch's PR. A branch's shippability is gated by the **Workspace Guard** (§3, uncommitted changes) and the **deployment-confirmation gate** (Ship Flow) — not by the todo queue. Do **not** issue an the agent's selection prompt here, and do **not** move tickets to icebox. If the developer wants to clear the queue first, that is their call to make outside `/ship` (e.g. via `/drive`).

## 5. Ship Flow

Ship the current branch's PR. (Worktree sync/cleanup and drive/trip routing are not here; in Claude Code those are handled by the trip workflow.)

**Merge is the LAST step, gated on a passing production confirmation.** Deploy and confirm happen from the work branch *before* the merge, so an unconfirmable change never reaches `main` — if confirmation fails, the branch simply isn't merged (that is the rollback). This order is the whole point of the deployment-confirmation gate; never merge first.

1. **Pre-check**: Run `bash ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: the PR is already on `main` and this confirmation-before-merge flow cannot re-gate it — warn the user, then proceed only to deploy/confirm/release for the already-merged commit. Capture `pr_number` and `url`.
2. **Catch up with `main`** (mandatory — before any deploy): Run `bash ship/scripts/catchup-main.sh "<base-branch>"` so what you deploy equals what will merge, and apply the §2-5b version-collision guard. On `caught_up:false`, branch on `conflict_class`: **`mechanical`** — the agent reconciles it itself as routine ship hygiene (merge `origin/main`, resolve the version/lockstep manifests, re-bump the version past the collision, regenerate `outputs/`, re-run the pre-merge proof), no user prompt; **`content`** — halt and ask the user to resolve the conflict before continuing. Never present reconciliation itself as an optional choice.
3. **Deploy** (gated on a confirmation method — see §1-4; this runs PRE-MERGE): Run `bash ship/scripts/read-deployments.sh` and `bash ship/scripts/find-claude-md.sh`.
   - **No confirmation method** (`has_confirmation` is `false` AND `CLAUDE.md` has no `## Verify` section): **HALT — do not deploy, do not merge, do not skip.** Apply the §1-4 hard gate: ask the user (the agent's selection prompt, at the command level) to provide a verification path / credentials, inspect production to establish one, author a `.workaholic/deployments/` entry, abort, or — deliberately — **merge without production confirmation** (the §1-4 accepted-risk bypass: record it via the step 5 bypass path, then proceed to merge). Aborting leaves `main` untouched. Resolve before proceeding.
   - **Confirmation method exists**: first run the **capability check** (§2-3c) for the target's `confirmation_method`. If `capable` is `false`, print the `missing`/`hint` as a warning — the declared method cannot run in this ship environment (e.g. a `browser` confirmation in headless/CI) and will force the post-deploy halt; steer the user toward a headless-executable method (`api-probe`/`db-query`) or an interactive ship before deploying. This is advisory: it does not override the §1-4 gate. Then take the deploy procedure from the matching `.workaholic/deployments/` `## Procedure` (preferred) or `CLAUDE.md` `## Deploy`, display it, ask confirmation via the agent's selection prompt (§1-3), and execute if confirmed. For a **deploy-on-merge** project (the deploy is triggered by the merge itself, e.g. a marketplace release published from the merge commit), the pre-merge "deploy + confirm" is the branch/staging-level proof the contract names (build/verify/test green, version correct); the merge then promotes to production and step 7 publishes/confirms the release. Capture the target's `confirmation_method` and `## Confirmation` (or `CLAUDE.md` `## Verify`) for step 4.
4. **Confirm in production** (execute the confirmation method, PRE-MERGE): run the captured confirmation and capture its observed result. Branch on `confirmation_method`:
   - `browser` — open the recorded `url` (browser tooling) and check the documented signal.
   - `server-batch` — run the documented batch command (credentials supplied transiently, never persisted).
   - `db-query` — run the documented query and compare against the expected result.
   - `api-probe` — probe the recorded `endpoint`.
   - `other` / `CLAUDE.md ## Verify` — follow the documented `## Confirmation` / `## Verify` steps.
   **A confirmation that runs and returns a failing result is a failed ship — do NOT merge, and it is NOT bypassable.** Report it prominently, leave the PR open, and stop. The branch staying open is the rollback. (Distinct from *cannot execute the confirmation at all* — e.g. the §2-3c capability check flagged the method as unrunnable in this environment: that is a cannot-confirm case, which falls back to the §1-4 accepted-risk bypass option, not a force-merge.)
5. **Record evidence and prepare merge artifacts** (PRE-MERGE): 
   - Append the proof to the story: `bash ship/scripts/record-evidence.sh "<branch>" "<target>" "<method>" "<non-secret result>" "pass"`.
   - **Bypass path only** (the developer chose the §1-4 accepted-risk override instead of a confirmation): record the bypass rather than a pass — `bash ship/scripts/record-evidence.sh "<branch>" "none" "none (accepted-risk bypass)" "<short note: production state unverified; merge-without-confirmation accepted by developer>" "bypassed"`. If it returns `no_story`, still surface the bypass in the PR body (next bullet) and the step-9 summary so the accepted-risk decision stays auditable. Then continue to merge.
   - Generate the release note: run `write-release-note` against `.workaholic/stories/<branch>.md`, passing the PR `url`. Write per its Output Location scheme.
   - Commit the evidence-updated story and the release note to the branch so both ride into the merge: `bash ship/scripts/commit-release-note.sh "<branch>"` (commit the story update alongside).
   - Update the PR body with the evidence so reviewers see the proof before merge: `bash report/scripts/create-or-update.sh "<branch>" "<title>"`.
6. **Merge PR** (LAST — only after a passing confirmation): Run `bash ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop. Capture the merge `commit_hash`.
7. **Publish GitHub Release** (post-merge, gated on a successful merge): Run `bash ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"`. The script first checks for an existing release-publishing GitHub Actions workflow and **defers** to it (`reason:"ci_publishes"`) — do nothing in that case, CI owns releases. Otherwise it creates the release (idempotent) targeting `merge-pr.sh`'s `commit_hash`. Derive `<tag>` from the project version (`.claude-plugin/marketplace.json` or the project's version file) when present, else the next semver after `gh release view`/the latest git tag; for an additional release on the same branch, suffix the tag to stay unique. `<notes-file>` is the note written in step 5. When CI is absent and a release will actually be created interactively, confirm via the agent's selection prompt first. Report `published`/`reason` from the JSON.
8. **Extract deferred concerns** (post-merge): Run `bash ship/scripts/extract-deferred-concerns.sh "<branch>" "<pr-number>" "<pr-url>"`. Persists active Concerns from the just-merged story's section 6 into `.workaholic/concerns/`. Commits the new files **and pushes**, so you end on `main` level with `origin/main` (the commit lands on local `main` post-merge; the push prevents a one-commit-ahead divergence). Skips silently when no story file exists or section 6 is empty. Report `extracted` count from the JSON output.
9. **Summarize**: catch-up result, deployment status, **confirmation result** (method used and pass/fail, with the recorded evidence, the unresolved-gate outcome if ship halted, or — distinctly — **merged WITHOUT production confirmation (accepted-risk bypass)** with the recorded bypass evidence), PR merge status (number, URL — emphasizing it merged only after confirmation passed), release-note status, GitHub Release status (published/deferred), and deferred concern extraction count.
