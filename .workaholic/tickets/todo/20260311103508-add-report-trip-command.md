---
created_at: 2026-03-11T10:35:08+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort:
commit_hash:
category:
---

# Add /report-trip Command to Trippin Plugin

## Overview

Create a new `/report-trip` command in the Trippin plugin that creates a pull request for the trip branch, generates a development journey report in `.workaholic/`, and uses that report as the PR description. The PR description is structured around the three-agent workflow artifacts: Planner (direction, test plan, test results), Architect (model, review), and Constructor (design, implementation). The report also includes the trip's `history.md` as a Journey section showing how the collaboration proceeded.

## Key Files

- `plugins/trippin/commands/trip.md` - Existing trip command; reference for worktree/branch conventions
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Artifact storage structure and agent responsibilities
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Worktree creation with branch naming conventions
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` - Trip directory initialization (`.workaholic/.trips/<trip-name>/`)
- `plugins/trippin/agents/planner.md` - Planner agent responsibilities (direction, test plan, testing)
- `plugins/trippin/agents/architect.md` - Architect agent responsibilities (model, structural review)
- `plugins/trippin/agents/constructor.md` - Constructor agent responsibilities (design, implementation)
- `plugins/drivin/skills/create-pr/SKILL.md` - Existing PR creation skill pattern (reference for reuse or cross-plugin invocation)
- `plugins/drivin/skills/create-pr/sh/create-or-update.sh` - Existing PR creation shell script
- `plugins/trippin/README.md` - Update with new command
- `plugins/trippin/.claude-plugin/plugin.json` - Plugin configuration
- `README.md` - Update Trippin command table

## Related History

The Trippin plugin was recently established with a three-agent workflow but currently has no reporting or PR creation capability. The Drivin plugin's `/report` (being renamed to `/report-drive`) provides the closest reference implementation, though the trip report structure differs significantly since it is organized around agent artifacts rather than ticket archives.

Past tickets that touched similar areas:

- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Established the `/report` command pattern in Drivin
- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Extended report command with additional subagent
- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215035-rename-core-to-drivin.md) - Established two-plugin architecture (Drivin + Trippin)
- [20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md](.workaholic/tickets/archive/drive-20260310-220224/20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md) - Recent enhancement to trip agents defining their current responsibilities

## Implementation Steps

1. **Create the report-trip command file** at `plugins/trippin/commands/report-trip.md`:
   - Frontmatter: `name: report-trip`, description referencing PR creation and journey report
   - Preload the `trip-protocol` skill for artifact path conventions
   - The command should accept the trip name as an argument (or detect it from the current branch)

2. **Define the command workflow** in `report-trip.md`:
   - **Step 1: Identify trip context** - Determine the trip name from the current branch (trip branches use `trip/<trip-name>` format) or from the argument. Locate the trip directory at `.workaholic/.trips/<trip-name>/`.
   - **Step 2: Gather trip artifacts** - Read all artifacts from the trip directory structure:
     - `directions/` - Planner's direction artifacts (latest approved version)
     - `directions/reviews/` - Direction review feedback
     - `models/` - Architect's model artifacts (latest approved version)
     - `models/reviews/` - Model review feedback
     - `designs/` - Constructor's design artifacts (latest approved version)
     - `designs/reviews/` - Design review feedback
   - **Step 3: Generate journey report** - Create a report file at `.workaholic/stories/<branch-name>.md` structured with agent-based sections (see Report Structure below)
   - **Step 4: Commit and push** - Stage the report, commit, and push the branch
   - **Step 5: Create PR** - Create a PR using the report as the body. Use `gh pr create` with the report content as `--body-file`. The PR title should summarize the trip direction.
   - **Step 6: Return PR URL** - Display the PR URL to the user

3. **Define the report structure** for the PR description:
   - **Planner section**: Direction summary (synthesized from latest approved direction), test plan summary, and test results
   - **Architect section**: Model summary (synthesized from latest approved model) and review summary (key structural observations)
   - **Constructor section**: Design summary (synthesized from latest approved design) and implementation summary
   - **Journey section**: Include the contents of `.workaholic/.trips/<trip-name>/history.md` showing how the collaboration proceeded. If `history.md` does not exist, generate a journey summary from the git commit log of the trip branch (commits follow the `[Agent] description` format from `trip-commit.sh`)

4. **Create a write-trip-report skill** at `plugins/trippin/skills/write-trip-report/SKILL.md`:
   - Define the report content structure and template
   - Specify how to extract summaries from each agent's artifacts
   - Define the PR description format with sections for each agent
   - Include guidelines for the Journey section

5. **Create a shell script** at `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh`:
   - Accept the trip name as argument
   - Locate and validate all trip artifacts exist
   - Output JSON with paths to latest versions of each artifact type
   - Handle the case where `history.md` does not exist

6. **Update `plugins/trippin/README.md`**:
   - Add `/report-trip` to the Commands table
   - Add `write-trip-report` to the Skills table

7. **Update `README.md`**:
   - Add `/report-trip` row to the Trippin command table

8. **Update `CLAUDE.md`** if applicable:
   - If the Trippin commands section is referenced anywhere, add the new command

## Considerations

- The report-trip command works on the trip branch (prefixed `trip/`), not on a drive branch. The PR should target `main` as base. (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`)
- The `history.md` file is mentioned in the requirements but is not currently generated by the trip protocol. Either the trip protocol should be extended to generate `history.md` during the trip session, or the report command should synthesize the journey from git commits. The git commit log approach is more robust since commit messages already follow the `[Agent] description` format. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
- The existing `create-pr` skill in Drivin is coupled to the story file format (strips YAML frontmatter, expects `.workaholic/stories/<branch>.md`). The Trippin report may need its own PR creation logic or a generalized version of the script. (`plugins/drivin/skills/create-pr/sh/create-or-update.sh`)
- The command should follow the thin command principle: orchestration only, with the report writing logic in the `write-trip-report` skill and artifact gathering in a shell script. (`CLAUDE.md` Architecture Policy)
- Cross-reference: The companion ticket to rename `/report` to `/report-drive` should be implemented first to avoid command name confusion. (`.workaholic/tickets/todo/20260311103507-rename-report-to-report-drive.md`)
- Unlike the Drivin report which invokes multiple parallel subagents (overview-writer, section-reviewer, performance-analyst, release-readiness), the trip report reads static artifacts directly. This keeps the command simpler. (`plugins/drivin/agents/story-writer.md`)
- The worktree isolation means the trip artifacts are only available inside the worktree directory, not the main repository. The report command must either run inside the worktree or know the worktree path to find artifacts. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 76-84)
