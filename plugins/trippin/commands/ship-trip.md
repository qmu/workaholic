---
name: ship-trip
description: Merge PR, clean up worktree, deploy to production, and verify deployment.
skills:
  - trip-protocol
  - ship
---

# Ship Trip

**Notice:** When user input contains `/ship-trip` - whether "run /ship-trip", "do /ship-trip", "ship /ship-trip", or similar - they likely want this command.

Merge the trip branch's pull request, clean up the worktree, deploy to production following cloud.md instructions, and verify the deployment.

## Instructions

### Step 1: Identify Trip Context

Determine the trip name from the current branch or argument:

- If `$ARGUMENT` is provided, use it as the trip name
- Otherwise, detect from current branch: `trip/<trip-name>` format

```bash
git branch --show-current
```

If the branch does not start with `trip/` and no argument was provided, check for available trip worktrees:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
```

Parse the JSON output and filter to worktrees where `has_pr` is `true` (trips with PRs ready to ship):

- If no shippable trip worktrees found: inform the user "No trip worktrees with open PRs found. Run `/report-trip` first to create a PR." and stop.
- If exactly one shippable trip worktree found: ask the user "Found trip '<trip_name>' with PR #<number>. Ship this trip?" using AskUserQuestion. If confirmed, use its `trip_name`.
- If multiple shippable trip worktrees found: list them with PR numbers and ask the user which one to ship using AskUserQuestion.

### Step 2: Pre-check

Run the pre-check script to verify a PR exists for the trip branch:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/pre-check.sh "trip/<trip-name>"
```

Parse the JSON output:
- If `found` is `false`: inform user "No PR found for this trip. Run `/report-trip` first." and stop.
- If `merged` is `true`: inform user "PR is already merged." and skip to Step 4 (Clean up worktree).
- Otherwise: proceed with the PR number to Step 3.

### Step 3: Merge PR

Run the merge script:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/merge-pr.sh "<pr-number>"
```

If merge fails, inform the user about the failure and stop. The worktree is preserved so the user can fix issues and retry.

On success, the local main branch is now at the merged revision.

### Step 4: Clean up worktree

Run the cleanup script to remove the worktree and local branch:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh "<trip-name>"
```

Report what was cleaned up (worktree path, branch name).

### Step 5: Deploy

Run the cloud.md finder from the repository root:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/ship/sh/find-cloud-md.sh
```

- If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to completion.
- If `found` is `true`: read the file and find the `## Deploy` section. Display the deploy instructions to the user, then ask for confirmation with AskUserQuestion: "Proceed with deployment?". If the user declines, report "Deployment skipped by user." and skip to completion. If confirmed, execute the instructions using Bash.

### Step 6: Verify

If cloud.md was found in Step 5, read the `## Verify` section and execute the verification steps. Report success or failure to the user.

If no cloud.md was found, skip this step.

### Step 7: Complete

Summarize what was done:
- PR merge status (number, URL)
- Worktree cleanup status
- Deployment status (executed or skipped)
- Verification results (pass/fail or skipped)
