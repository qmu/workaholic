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
