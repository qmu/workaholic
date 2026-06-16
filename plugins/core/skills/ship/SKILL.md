---
name: ship
description: Use when the user runs `/ship`, asks to "merge and deploy", "ship this branch", or "push to production". Pre-checks the workspace and todo queue, confirms with the user, merges the current branch's PR on GitHub, runs the deploy steps from CLAUDE.md's `## Deploy` section, and reports the outcome.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
metadata:
  internal: true
---

# Ship

Merge a pull request, deploy to production, and verify the deployment. The agent acts as the deployment agent, following the `## Deploy` and `## Verify` instructions in the project's `CLAUDE.md`.

This skill is the **trip-independent ship essence**: it operates on the current branch's PR. Worktree handling and drive/trip context routing are not part of this skill — in Claude Code they are handled separately by the trip workflow and the `/ship` command. Any agent can run this skill directly to ship the current branch.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Where a step uses `AskUserQuestion` (workspace/ticket guards, deploy confirmation), use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The confirmations are mandatory; only the prompt mechanism varies. (This skill has no subagent fan-out.)

## 1. CLAUDE.md Convention

Deploy and verify instructions live in the project's `CLAUDE.md` — the file authored by the user that already carries the project's instructions. The ship workflow reads its `## Deploy` and `## Verify` sections to learn how to deploy and verify.

### 1-1. Search Order

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-claude-md.sh
```

Searches: `./CLAUDE.md`

### 1-2. Expected Sections

```markdown
## Deploy
Step-by-step deployment instructions for the agent to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

### 1-3. Confirmation

Before executing deploy instructions, display the Deploy section and ask the user to confirm via AskUserQuestion. If the user declines, deployment is skipped.

### 1-4. Fallback

If no `CLAUDE.md` is found, or it has no `## Deploy` section, skip deploy and verify steps. Inform the user that deployment was skipped because `CLAUDE.md` carried no deploy instructions.

## 2. Shell Scripts

### 2-1. Pre-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"
```

Verifies a PR exists for the branch. Returns JSON with PR number, URL, and merge status.

### 2-2. Merge PR

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"
```

Merges the PR, checks out main, and pulls to sync. Returns JSON with merge status and commit hash.

### 2-3. Find CLAUDE.md

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-claude-md.sh
```

Searches for the project's `CLAUDE.md`. Returns JSON with path or `{"found": false}`.

### 2-4. Check Todo

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Checks if the current user's `.workaholic/tickets/todo/<user>/` queue has remaining tickets. Returns JSON with cleanliness status, count, and ticket list. Used as a pre-merge guard to prevent shipping with unfinished work. The check is scoped to the current user's subdirectory: other developers' tickets (in their own subdirectories, or unswept at the `todo/` root) do not block the merge.

### 2-4b. Commit Release Note

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/commit-release-note.sh "<branch>"
```

Stages, commits (`Add release notes for <branch>`), and pushes any note file(s) under `.workaholic/release-notes/` so they ride into the merge. Returns `{committed, branch}` or `{committed:false, reason:"no_release_note_changes"}`. Run after `core:write-release-note` has written the note and before `merge-pr.sh`.

### 2-5. Extract Carry-Overs

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"
```

Reads the just-shipped story (`.workaholic/stories/<branch>.md`), parses each `###` concern block in section 6 (Concerns), and writes one file per concern under `.workaholic/concerns/` as `<pr-number>-<slug>.md` (with `severity` and a Title/Description/How-to-Fix body). Returns JSON:

```json
{"status":"ok","extracted":10,"files":["..."]}
```

Commits the new files with message `Carry over concerns from PR #<pr-number>` so the corpus stays under version control. Skips silently when no story file exists or section 6 is empty.

### 2-6. Publish GitHub Release

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"
```

Publishes a GitHub Release from the generated note **unless** the repo already has a GitHub Actions workflow that publishes releases (scans `.github/workflows/` for `gh release create` / `softprops/action-gh-release` / `actions/create-release`). Returns `{published:false, reason:"ci_publishes"}` when CI owns publishing, `{published:false, reason:"no_notes_file"|"already_exists"}` for the safe no-ops, or `{published:true, tag, url, reason:"created"}`. Idempotent: never errors on an existing tag. Targets the merge commit.

## 3. Workspace Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ticket Guard.

If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the workflow so you can handle the changes first.

If the user selects "Stop", end the workflow immediately.

## 4. Ticket Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ship Flow.

If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in your `.workaholic/tickets/todo/<user>/` queue:" followed by the ticket filenames. Then ask via AskUserQuestion with selectable options:
- **"Move all to icebox"** - Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to the Ship Flow.
- **"Stop"** - Halt the workflow so you can handle tickets first (run `/drive`, manually reorganize, etc.)

If the user selects "Stop", end the workflow immediately.

## 5. Ship Flow

Ship the current branch's PR. (Worktree sync/cleanup and drive/trip routing are not here; in Claude Code those are handled by the trip workflow.)

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy. Capture `pr_number` and `url`.
2. **Generate release note**: Run the `core:write-release-note` skill against `.workaholic/stories/<branch>.md`, passing the PR `url` from step 1. Write the note per its Output Location scheme (first release → `.workaholic/release-notes/<branch>.md`; an additional ship on the same branch → `<branch>-<N>.md`). Then commit it to the branch with `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/commit-release-note.sh "<branch>"` so it is included in the merge. Skip silently if no story file exists.
3. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
4. **Extract carry-overs**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"`. Persists active Concerns from the just-shipped story's section 6 into `.workaholic/concerns/`. Commits the new files. Skips silently when no story file exists or section 6 is empty. Report `extracted` count from the JSON output.
5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-claude-md.sh`. If `found` is `false`, or `CLAUDE.md` has no `## Deploy` section: inform user "No deploy instructions found in CLAUDE.md. Deployment skipped." and skip to summary. Otherwise: read `CLAUDE.md`, find the `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
6. **Verify**: If a `## Deploy` section was found, read the `## Verify` section of `CLAUDE.md` and execute. Report results.
7. **Publish GitHub Release** (gated on a successful merge): Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"`. The script first checks for an existing release-publishing GitHub Actions workflow and **defers** to it (`reason:"ci_publishes"`) — do nothing in that case, CI owns releases. Otherwise it creates the release (idempotent) targeting `merge-pr.sh`'s `commit_hash`. Derive `<tag>` from the project version (`.claude-plugin/marketplace.json` or the project's version file) when present, else the next semver after `gh release view`/the latest git tag; for an additional release on the same branch, suffix the tag to stay unique. `<notes-file>` is the note written in step 2. When CI is absent and a release will actually be created interactively, confirm via AskUserQuestion first. Report `published`/`reason` from the JSON.
8. **Summarize**: PR merge status (number, URL), release-note commit status, carry-over extraction count, deployment status, verification results, and GitHub Release status (published/deferred).
