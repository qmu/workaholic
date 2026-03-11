---
name: ship-drive
description: Merge PR, deploy to production, and verify deployment.
skills:
  - ship
---

# Ship Drive

**Notice:** When user input contains `/ship-drive` - whether "run /ship-drive", "do /ship-drive", "ship /ship-drive", or similar - they likely want this command.

Merge the current branch's pull request, deploy to production following cloud.md instructions, and verify the deployment.

## Instructions

### Step 1: Pre-check

Run the pre-check script to verify a PR exists for the current branch:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/pre-check.sh "<current-branch>"
```

Get the current branch name:

```bash
git branch --show-current
```

Parse the JSON output:
- If `found` is `false`: inform user "No PR found for this branch. Run `/report-drive` first." and stop.
- If `merged` is `true`: inform user "PR is already merged." and skip to Step 3 (Deploy).
- Otherwise: proceed with the PR number to Step 2.

### Step 2: Merge PR

Run the merge script:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/merge-pr.sh "<pr-number>"
```

If merge fails, inform the user about the failure (merge conflicts, failed checks, etc.) and stop.

On success, the local main branch is now at the merged revision.

### Step 3: Deploy

Run the cloud.md finder:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/find-cloud-md.sh
```

- If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to completion.
- If `found` is `true`: read the file, find the `## Deploy` section, and execute the instructions using Bash.

### Step 4: Verify

If cloud.md was found in Step 3, read the `## Verify` section and execute the verification steps. Report success or failure to the user.

If no cloud.md was found, skip this step.

### Step 5: Complete

Summarize what was done:
- PR merge status (number, URL)
- Deployment status (executed or skipped)
- Verification results (pass/fail or skipped)
