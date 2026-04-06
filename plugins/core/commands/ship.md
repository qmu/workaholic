---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - work:trip-protocol
  - ship
  - branching
---

# Ship

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

Context-aware ship command that auto-detects whether you are in a drive or trip workflow, merges the PR, deploys, and verifies. For trip workflows, it additionally cleans up the worktree.

## Instructions

### Step 0: Workspace Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.

If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the command so you can handle the changes first.

If the user selects "Stop", end the command immediately.

### Step 0.5: Ticket Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.

If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in `.workaholic/tickets/todo/`:" followed by the ticket filenames. Then ask via AskUserQuestion with selectable options:
- **"Move all to icebox"** - Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to Step 1.
- **"Stop"** - Halt the command so you can handle tickets first (run `/drive`, manually reorganize, etc.)

If the user selects "Stop", end the command immediately.

### Step 1: Detect Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

Parse the JSON output. Route to the appropriate workflow based on `context`.

### Step 2: Route by Context

#### Work Context (`context: "work"`)

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
6. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
7. **Summarize**: PR merge status (number, URL), gitignored file sync status, worktree cleanup status, deployment status, verification results.

#### Worktree Context (`context: "worktree"`)

Not on a work branch, but worktrees exist.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`
2. Filter to worktrees where `has_pr` is `true` (branches with PRs ready to ship)
3. If no shippable worktrees found: inform the user "No worktrees with open PRs found. Run `/report` first." and stop.
4. If exactly one shippable worktree: ask the user "Found '<name>' with PR #<number>. Ship?" using AskUserQuestion. If confirmed, use it.
5. If multiple shippable worktrees: list them with PR numbers and ask the user which one to ship using AskUserQuestion.
6. Once selected, follow Work Context steps 1-6.

#### Unknown Context (`context: "unknown"`)

Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
