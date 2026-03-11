---
created_at: 2026-03-11T10:56:13+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config, Infrastructure]
effort:
commit_hash:
category:
---

# Add /ship-drive Command to Drivin Plugin

## Overview

Create a new `/ship-drive` command in the Drivin plugin that completes the delivery workflow after `/report-drive` has created a pull request. The command merges the PR, deploys to production, and verifies the deployment -- all orchestrated by Claude Code, not GitHub Actions. This ticket also establishes the `cloud.md` convention: a user-provided or skill-provided instruction file that tells the ship command how to deploy and verify a given project.

The ship workflow has four steps: pre-check (verify PR exists), merge PR (merge and sync local main), deploy (follow cloud.md instructions), and verify (run health checks per cloud.md). This extends the Drivin lifecycle from plan-implement-report to plan-implement-report-ship.

## Key Files

- `plugins/drivin/commands/report-drive.md` - Existing report command that creates the PR; ship-drive runs after this
- `plugins/drivin/skills/create-pr/sh/create-or-update.sh` - Reference for how PRs are managed with `gh` CLI
- `plugins/drivin/skills/gather-git-context/SKILL.md` - Gathers branch and repo context needed for PR lookup
- `plugins/drivin/skills/branching/sh/check.sh` - Branch detection logic
- `plugins/drivin/rules/general.md` - General rules including commit restrictions; ship-drive will need to be listed as a command with commit/merge steps
- `plugins/drivin/README.md` - Needs new command entry
- `plugins/drivin/.claude-plugin/plugin.json` - Plugin configuration
- `CLAUDE.md` - Commands table and Development Workflow section need updating
- `README.md` - Drivin command table and typical session example need updating

## Related History

The delivery pipeline currently ends at PR creation. The report command (recently renamed from `/report` to `/report-drive`) creates PRs but merging, deployment, and verification are entirely manual. No existing tickets have addressed shipping, deployment, or cloud configuration.

Past tickets that touched similar areas:

- [20260311103507-rename-report-to-report-drive.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103507-rename-report-to-report-drive.md) - Renamed /report to /report-drive, establishing the -drive suffix convention for Drivin commands
- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) - Added /report-trip, establishing the pattern of paired commands across plugins
- [20260202204111-fix-release-action-trigger-on-merge.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md) - Fixed release action trigger on PR merge; relevant context for merge behavior

## Implementation Steps

1. **Define the cloud.md convention** by creating a `ship` skill at `plugins/drivin/skills/ship/SKILL.md`:
   - Document that `cloud.md` is a project-level file (placed in the consuming project's root or `.workaholic/` directory) that describes how to deploy and verify
   - Define the expected sections in cloud.md: `## Deploy` (step-by-step deployment instructions Claude Code should execute) and `## Verify` (health checks, smoke tests, expected outcomes)
   - Document that cloud.md is NOT a Workaholic plugin file -- it is authored by the user in their project
   - Specify the search order: `./cloud.md`, `./.workaholic/cloud.md`
   - Document fallback behavior if no cloud.md is found: skip deploy/verify steps and inform the user

2. **Create shell scripts for the ship skill**:
   - `plugins/drivin/skills/ship/sh/pre-check.sh`: Accept branch name, verify PR exists for the branch using `gh pr list --head <branch>`, output JSON with PR number, URL, and merge status
   - `plugins/drivin/skills/ship/sh/merge-pr.sh`: Accept PR number, merge the PR using `gh pr merge <number> --merge`, then sync local main (`git checkout main && git pull origin main`), output JSON with merge status and merged commit hash
   - `plugins/drivin/skills/ship/sh/find-cloud-md.sh`: Search for cloud.md in standard locations, output JSON with the path if found or `{"found": false}` if not

3. **Create the ship-drive command** at `plugins/drivin/commands/ship-drive.md`:
   - Frontmatter: `name: ship-drive`, description referencing PR merge and deployment
   - Preload the `ship` skill for cloud.md convention and deployment knowledge
   - **Step 1: Pre-check** - Run `pre-check.sh` with the current branch. If no PR found, inform user and stop. If PR is already merged, inform user and skip to deploy.
   - **Step 2: Merge PR** - Run `merge-pr.sh` with the PR number. Handle merge conflicts or failed checks by informing the user.
   - **Step 3: Deploy** - Run `find-cloud-md.sh` to locate the cloud.md file. If found, read the `## Deploy` section and execute the instructions. If not found, inform user that deployment was skipped.
   - **Step 4: Verify** - If cloud.md was found, read the `## Verify` section and execute the verification steps. Report success or failure to the user.
   - Keep to ~50-80 lines (orchestration only)

4. **Update `plugins/drivin/rules/general.md`**:
   - Add `/ship-drive` to the list of commands with commit/merge steps

5. **Update `plugins/drivin/README.md`**:
   - Add `/ship-drive` to the Commands table
   - Add `ship` to the Skills table
   - Update Workflow section to add step 4: ship

6. **Update `CLAUDE.md`**:
   - Add `/ship-drive` to the Commands table
   - Update Development Workflow to add step 4 between Create PR and Release
   - Update Project Structure comment for drivin commands

7. **Update `README.md`**:
   - Add `/ship-drive` to the Drivin command table
   - Update typical session example to include `/ship-drive` after `/report-drive`
   - Update How It Works section to mention the ship step

## Considerations

- The `cloud.md` file is user-authored and project-specific, not part of the Workaholic plugin. The ship skill should document the expected format but never create or modify `cloud.md`. (`plugins/drivin/skills/ship/SKILL.md`)
- Merging a PR triggers the GitHub release action (see archived ticket about release action trigger on merge). The ship command should be aware that merging may trigger CI pipelines, but since Claude Code handles deployment directly, these are independent concerns. (`plugins/drivin/skills/ship/sh/merge-pr.sh`)
- The `gh pr merge` command supports multiple merge strategies (--merge, --squash, --rebase). The default should be `--merge` but the cloud.md could specify a preference. Consider whether merge strategy belongs in cloud.md or as a command argument. (`plugins/drivin/skills/ship/sh/merge-pr.sh`)
- After merging, the local branch becomes stale. The merge script must switch to main and pull to ensure subsequent deploy commands run from the merged revision. (`plugins/drivin/skills/ship/sh/merge-pr.sh`)
- The deploy step executes arbitrary instructions from cloud.md, which could include AWS CLI commands, SSH connections, Docker operations, etc. The command should not restrict what tools are available -- it reads cloud.md and follows the instructions using Bash. (`plugins/drivin/commands/ship-drive.md`)
- If cloud.md is not found, the command should still complete the merge step successfully. Deploy and verify are optional steps that enhance the workflow but are not required. (`plugins/drivin/skills/ship/SKILL.md`)
- Per CLAUDE.md shell script principle, all conditional logic (PR existence check, cloud.md search, merge status handling) must be in shell scripts, not inline in the command markdown. (`plugins/drivin/skills/ship/sh/`)
- Cross-reference: The companion `/ship-trip` ticket in the Trippin plugin builds on the cloud.md convention established here and adds worktree cleanup. (`.workaholic/tickets/todo/20260311105614-add-ship-trip-command.md`)
