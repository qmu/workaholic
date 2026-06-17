---
name: ship
description: Use when the user runs `/ship`, asks to "merge and deploy", "ship this branch", or "push to production". Pre-checks the workspace and todo queue, confirms with the user, merges the current branch's PR on GitHub, runs the deploy steps from CLAUDE.md's `## Deploy` section, and reports the outcome.
allowed-tools: Bash, Read, Glob, Grep
---

# Ship

Merge a pull request, deploy to production, and **confirm the deployment actually succeeded in production**. The agent acts as the deployment agent, following the deployment procedure and — critically — the success-confirmation method declared for the target.

**Core design: ship requires an established way to confirm the deployment.** A deployment that cannot be confirmed is not shippable. If no documented confirmation method exists (neither a `.workaholic/deployments/` entry nor a `CLAUDE.md` `## Verify` section), ship does **not** silently skip — it **halts** and asks the user to provide a verification path or credentials to confirm the change reached production, or to author a `.workaholic/deployments/` entry. The confirmation is then **executed** after the deploy and its result reported; a failed confirmation is a failed ship.

This skill is the **trip-independent ship essence**: it operates on the current branch's PR. Worktree handling and drive/trip context routing are not part of this skill — in Claude Code they are handled separately by the trip workflow and the `/ship` command. Any agent can run this skill directly to ship the current branch.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses the agent's selection prompt (workspace/ticket guards, deploy confirmation, the §1-4 no-confirmation-method halt), use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The confirmations are mandatory; only the prompt mechanism varies. (This skill has no subagent fan-out.)

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

Determine whether an established confirmation method exists: `read-deployments.sh` returns `has_confirmation: true`, **or** `CLAUDE.md` has a non-empty `## Verify` section.

- **If a confirmation method exists** — proceed: run the confirm-before-deploy gate (§1-3), deploy, then **execute** the confirmation (§5 step 6) and report its result.
- **If no confirmation method exists** — **HALT. Do not deploy, do not silently skip.** Ask the user (via the agent's selection prompt, at the command/main-agent level) how to establish confirmation. Options:
  - **Provide a verification path / credentials now** — the user supplies the URL, command, or transient credentials to sign into the production web system or server so the change can be confirmed. (Credentials are used transiently — never written to `.workaholic/deployments/*.md`, shell profiles, or global config.)
  - **Inspect production first** — ship inspects the production web system (e.g. via browser tooling) to determine how the deploy can be assured, then records it as a `.workaholic/deployments/` entry.
  - **Author a `.workaholic/deployments/` entry** — pause so the user (or the agent) writes the contract, then re-run.
  - **Abort the ship** — stop without deploying.

A docs/config-only project legitimately may have a trivial confirmation (e.g. "the merge to `main` is the deployment; confirm the commit is on `main`"); that still must be stated as a confirmation method, not left absent.

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

### 2-4. Check Todo

```bash
bash ship/scripts/check-todo.sh
```

Checks if the current user's `.workaholic/tickets/todo/<user>/` queue has remaining tickets. Returns JSON with cleanliness status, count, and ticket list. Used as a pre-merge guard to prevent shipping with unfinished work. The check is scoped to the current user's subdirectory: other developers' tickets (in their own subdirectories, or unswept at the `todo/` root) do not block the merge.

### 2-4b. Commit Release Note

```bash
bash ship/scripts/commit-release-note.sh "<branch>"
```

Stages, commits (`Add release notes for <branch>`), and pushes any note file(s) under `.workaholic/release-notes/` so they ride into the merge. Returns `{committed, branch}` or `{committed:false, reason:"no_release_note_changes"}`. Run after `write-release-note` has written the note and before `merge-pr.sh`.

### 2-5. Extract Carry-Overs

```bash
bash ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"
```

Reads the just-shipped story (`.workaholic/stories/<branch>.md`), parses each `###` concern block in section 6 (Concerns), and writes one file per concern under `.workaholic/concerns/` as `<pr-number>-<slug>.md` (with `severity` and a Title/Description/How-to-Fix body). Returns JSON:

```json
{"status":"ok","extracted":10,"files":["..."]}
```

Commits the new files with message `Carry over concerns from PR #<pr-number>` so the corpus stays under version control. Skips silently when no story file exists or section 6 is empty.

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

## 4. Ticket Guard

```bash
bash ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ship Flow.

If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in your `.workaholic/tickets/todo/<user>/` queue:" followed by the ticket filenames. Then ask via the agent's selection prompt with selectable options:
- **"Move all to icebox"** - Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to the Ship Flow.
- **"Stop"** - Halt the workflow so you can handle tickets first (run `/drive`, manually reorganize, etc.)

If the user selects "Stop", end the workflow immediately.

## 5. Ship Flow

Ship the current branch's PR. (Worktree sync/cleanup and drive/trip routing are not here; in Claude Code those are handled by the trip workflow.)

1. **Pre-check**: Run `bash ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy. Capture `pr_number` and `url`.
2. **Generate release note**: Run the `write-release-note` skill against `.workaholic/stories/<branch>.md`, passing the PR `url` from step 1. Write the note per its Output Location scheme (first release → `.workaholic/release-notes/<branch>.md`; an additional ship on the same branch → `<branch>-<N>.md`). Then commit it to the branch with `bash ship/scripts/commit-release-note.sh "<branch>"` so it is included in the merge. Skip silently if no story file exists.
3. **Merge PR**: Run `bash ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
4. **Extract carry-overs**: Run `bash ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"`. Persists active Concerns from the just-shipped story's section 6 into `.workaholic/concerns/`. Commits the new files. Skips silently when no story file exists or section 6 is empty. Report `extracted` count from the JSON output.
5. **Deploy** (gated on a confirmation method — see §1-4): Run `bash ship/scripts/read-deployments.sh` and `bash ship/scripts/find-claude-md.sh`.
   - **No confirmation method** (`has_confirmation` is `false` AND `CLAUDE.md` has no `## Verify` section): **HALT — do not deploy, do not skip.** Apply the §1-4 hard gate: ask the user (the agent's selection prompt, at the command level) to provide a verification path / credentials, inspect production to establish one, author a `.workaholic/deployments/` entry, or abort. Resolve before proceeding.
   - **Confirmation method exists**: take the deploy procedure from the matching `.workaholic/deployments/` `## Procedure` (preferred) or `CLAUDE.md` `## Deploy`, display it, ask confirmation via the agent's selection prompt (§1-3), and execute if confirmed. Capture the target's `confirmation_method` and `## Confirmation` (or `CLAUDE.md` `## Verify`) for step 6.
6. **Confirm** (execute the confirmation method): after a successful deploy, run the captured confirmation and report its result. Branch on `confirmation_method`:
   - `browser` — open the recorded `url` (browser tooling) and check the documented signal.
   - `server-batch` — run the documented batch command (credentials supplied transiently, never persisted).
   - `db-query` — run the documented query and compare against the expected result.
   - `api-probe` — probe the recorded `endpoint`.
   - `other` / `CLAUDE.md ## Verify` — follow the documented `## Confirmation` / `## Verify` steps.
   **A failed confirmation is a failed ship** — report it prominently; do not present the deploy as successful.
7. **Publish GitHub Release** (gated on a successful merge): Run `bash ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"`. The script first checks for an existing release-publishing GitHub Actions workflow and **defers** to it (`reason:"ci_publishes"`) — do nothing in that case, CI owns releases. Otherwise it creates the release (idempotent) targeting `merge-pr.sh`'s `commit_hash`. Derive `<tag>` from the project version (`.claude-plugin/marketplace.json` or the project's version file) when present, else the next semver after `gh release view`/the latest git tag; for an additional release on the same branch, suffix the tag to stay unique. `<notes-file>` is the note written in step 2. When CI is absent and a release will actually be created interactively, confirm via the agent's selection prompt first. Report `published`/`reason` from the JSON.
8. **Summarize**: PR merge status (number, URL), release-note commit status, carry-over extraction count, deployment status, **confirmation result** (method used and pass/fail, or the unresolved-gate outcome if ship halted), and GitHub Release status (published/deferred).
