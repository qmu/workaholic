---
name: report
description: Generate documentation (changelog, story, specs, terms) and create/update a pull request.
---

# Report

Generate comprehensive documentation and create or update a pull request for the current branch.

The story file in `.workaholic/stories/<branch-name>.md` contains the complete PR description. Seven sections: 1. Summary, 2. Motivation, 3. Journey, 4. Changes, 5. Outcome, 6. Performance, 7. Notes.

This design makes stories the single source of truth for PR content, eliminating duplication between story generation and PR description assembly.

## Critical Behavior

- **ALWAYS display the PR URL** when finished (see Completion Output section)

## Instructions

1. Check the current branch name with `git branch --show-current`
2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
3. **Check for remaining tickets**:
   - List files in `.workaholic/tickets/*.md` (excluding README.md)
   - If any tickets exist:
     - Warn the user: "Found X unfinished ticket(s) that will be moved to icebox:"
     - List the ticket filenames
     - Create `.workaholic/tickets/icebox/` if it doesn't exist
     - Move each ticket to `.workaholic/tickets/icebox/`
     - Stage and commit: "Move remaining tickets to icebox"
   - If no tickets, continue with normal PR flow
4. **Generate documentation** using 4 subagents concurrently:

   Invoke all 4 documentation agents in parallel via Task tool (single message with 4 tool calls):

   - **changelog-writer** (`subagent_type: "core:changelog-writer"`): Updates `CHANGELOG.md` with entries from archived tickets
   - **story-writer** (`subagent_type: "core:story-writer"`): Creates `.workaholic/stories/<branch-name>.md` with PR narrative
   - **spec-writer** (`subagent_type: "core:spec-writer"`): Updates `.workaholic/specs/` to reflect codebase changes
   - **terms-writer** (`subagent_type: "core:terms-writer"`): Updates `.workaholic/terms/` with new terms

   Pass to each agent:
   - Branch name and base branch as context
   - Repository URL (for changelog-writer)

   Wait for all 4 agents to complete. Each writes to different locations:
   - `CHANGELOG.md`
   - `.workaholic/stories/<branch-name>.md`
   - `.workaholic/specs/**/*.md`
   - `.workaholic/terms/**/*.md`

   After all complete, stage all changes and commit: "Update documentation for PR"

   **Failure handling**: If any agent fails, report which succeeded and which failed. Continue with PR creation if story-writer succeeded (it's required for PR body).

5. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
6. **Push branch to remote**:
   ```bash
   git push -u origin <branch-name>
   ```
   This ensures the branch exists on remote before PR creation. The `-u` flag sets upstream tracking for new branches.
7. **Create or update PR** using the pr-creator subagent:

   Invoke the pr-creator subagent via Task tool with `subagent_type: "core:pr-creator"`:

   - Pass the branch name and base branch as context
   - The subagent handles: checking if PR exists, reading story file, deriving title, `gh` CLI operations
   - The subagent returns the PR URL (required for completion output)

## Completion Output (MANDATORY)

After creating or updating the PR, you **MUST** display the result:

- **New PR**: `PR created: <PR-URL>`
- **Updated PR**: `PR updated: <PR-URL>`

This URL display is **mandatory** - the command is NOT complete without it. The user needs the URL to review and share the PR.

