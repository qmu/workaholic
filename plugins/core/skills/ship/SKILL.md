---
name: ship
description: Ship workflow - merge PR, deploy via cloud.md, and verify production.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
---

# Ship

Merge a pull request, deploy to production, and verify the deployment. Claude Code acts as the deployment agent, following instructions from a user-provided `cloud.md` file.

## 1. Cloud.md Convention

`cloud.md` is a project-level file authored by the user (not part of Workaholic). It tells the ship command how to deploy and verify.

### 1-1. Search Order

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh
```

Searches: `./cloud.md`, `./.workaholic/cloud.md`

### 1-2. Expected Sections

```markdown
## Deploy
Step-by-step deployment instructions for Claude Code to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

### 1-3. Confirmation

Before executing deploy instructions, the ship command displays the Deploy section and asks for user confirmation via AskUserQuestion. If the user declines, deployment is skipped.

### 1-4. Fallback

If no `cloud.md` is found, skip deploy and verify steps. Inform the user that deployment was skipped because no `cloud.md` was found.

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

### 2-3. Find cloud.md

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh
```

Searches for cloud.md in standard locations. Returns JSON with path or `{"found": false}`.

### 2-4. Check Todo

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Checks if `.workaholic/tickets/todo/` has remaining tickets. Returns JSON with cleanliness status, count, and ticket list. Used as a pre-merge guard to prevent shipping with unfinished work.

### 2-5. Find Gitignored Files

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"
```

Discovers gitignored files in a worktree that differ from the main repo root. Excludes reinstallable directories (`node_modules/`, `.venv/`, `vendor/bundle/`, `.cache/`, `__pycache__/`) and files over 1MB. Returns JSON:

```json
{"has_changes": true, "files": [{"path": ".env", "status": "modified", "size": "1KB"}]}
```

Status is `new` (exists only in worktree) or `modified` (differs from main copy).

### 2-6. Sync Gitignored Files

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'
```

Copies selected gitignored files from the worktree to the main repo root, creating parent directories as needed. `<files-json>` is a JSON array of relative paths. Returns JSON:

```json
{"synced": true, "count": 2, "files": [".env", ".local.md"]}
```

## 3. Workspace Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ticket Guard.

If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the command so you can handle the changes first.

If the user selects "Stop", end the workflow immediately.

## 4. Ticket Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to Detect Context.

If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in `.workaholic/tickets/todo/`:" followed by the ticket filenames. Then ask via AskUserQuestion with selectable options:
- **"Move all to icebox"** - Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to Detect Context.
- **"Stop"** - Halt the command so you can handle tickets first (run `/drive`, manually reorganize, etc.)

If the user selects "Stop", end the workflow immediately.

## 5. Detect Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

Parse the JSON output. Route to the appropriate workflow based on `context`.

## 6. Route by Context

### Work Context (`context: "work"`)

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
6. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
7. **Summarize**: PR merge status (number, URL), gitignored file sync status, worktree cleanup status, deployment status, verification results.

### Worktree Context (`context: "worktree"`)

Not on a work branch, but worktrees exist.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
2. Filter to worktrees where `has_pr` is `true` (branches with PRs ready to ship)
3. If no shippable worktrees found: inform the user "No worktrees with open PRs found. Run `/report` first." and stop.
4. If exactly one shippable worktree: ask the user "Found '<name>' with PR #<number>. Ship?" using AskUserQuestion. If confirmed, use it.
5. If multiple shippable worktrees: list them with PR numbers and ask the user which one to ship using AskUserQuestion.
6. Once selected, follow Work Context steps 1-6.

### Unknown Context (`context: "unknown"`)

Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
