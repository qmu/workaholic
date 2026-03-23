---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - trippin:trip-protocol
  - trippin:ship
  - branching
---

# Ship

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

Context-aware ship command that auto-detects whether you are in a drive or trip workflow, merges the PR, deploys, and verifies. For trip workflows, it additionally cleans up the worktree.

## Instructions

### Step 1: Detect Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/detect-context.sh
```

Parse the JSON output. Route to the appropriate workflow based on `context`.

### Step 2: Route by Context

#### Drive Context (`context: "drive"`)

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy.
2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
3. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
4. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
5. **Summarize**: PR merge status (number, URL), deployment status, verification results.

#### Trip Context (`context: "trip"`)

Use the `trip_name` from the detection result, or `$ARGUMENT` if provided.

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/pre-check.sh "trip/<trip-name>"`. If `found` is `false`: inform user "No PR found for this trip. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/ship/sh/merge-pr.sh "<pr-number>"`. On failure, inform user and stop (worktree preserved).
3. **Clean up worktree**: Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/cleanup-worktree.sh "<trip-name>"`. Report what was cleaned up.
4. **Deploy**: Same as Drive Context step 3 (from repo root after merge).
5. **Verify**: Same as Drive Context step 4.
6. **Summarize**: PR merge status, worktree cleanup status, deployment status, verification results.

#### Trip-Drive Hybrid Context (`context: "trip_drive"`)

This branch started as a trip and has drive-style tickets. Follow the Drive Context shipping workflow (steps 1-5), then additionally clean up the trip worktree:

1. Follow Drive Context steps 1-5 (pre-check, merge, deploy, verify, summarize)
2. **Clean up worktree**: After successful merge, run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/cleanup-worktree.sh "<trip_name>"` using `trip_name` from detection result. Report what was cleaned up.

#### Trip Worktree Context (`context: "trip_worktree"`)

Not on a trip branch, but trip worktrees exist.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../trippin/skills/trip-protocol/sh/list-trip-worktrees.sh`
2. Filter to worktrees where `has_pr` is `true` (trips with PRs ready to ship)
3. If no shippable trips found: inform the user "No trip worktrees with open PRs found. Run `/report` first." and stop.
4. If exactly one shippable trip: ask the user "Found trip '<trip_name>' with PR #<number>. Ship this trip?" using AskUserQuestion. If confirmed, use it.
5. If multiple shippable trips: list them with PR numbers and ask the user which one to ship using AskUserQuestion.
6. Once selected, follow Trip Context steps 1-6.

#### Unknown Context (`context: "unknown"`)

Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
