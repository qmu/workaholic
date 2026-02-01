---
name: story
description: Generate documentation (changelog, story, specs, terms) and create/update a pull request.
---

# Story

> When user input contains `/story` - whether "run /story", "do /story", "update /story", or similar - they likely want this command.

Generate comprehensive documentation and create or update a pull request for the current branch.

The story file in `.workaholic/stories/<branch-name>.md` contains the complete PR description. Eleven sections: 1. Overview, 2. Motivation, 3. Journey, 4. Changes, 5. Outcome, 6. Historical Analysis, 7. Concerns, 8. Ideas, 9. Performance, 10. Release Preparation, 11. Notes.

This design makes stories the single source of truth for PR content, eliminating duplication between story generation and PR description assembly.

## Critical Behavior

- **ALWAYS display the PR URL** when finished (see Completion Output section)

## Instructions

1. Check the current branch name with `git branch --show-current`
2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
3. **Generate documentation** using 6 subagents:

   **Phase 1**: Invoke 5 agents in parallel via Task tool (single message with 5 tool calls, each with `model: "haiku"`):

   - **changelog-writer** (`subagent_type: "core:changelog-writer"`, `model: "haiku"`): Updates `CHANGELOG.md` with entries from archived tickets
   - **spec-writer** (`subagent_type: "core:spec-writer"`, `model: "haiku"`): Updates `.workaholic/specs/` to reflect codebase changes
   - **terms-writer** (`subagent_type: "core:terms-writer"`, `model: "haiku"`): Updates `.workaholic/terms/` with new terms
   - **release-readiness** (`subagent_type: "core:release-readiness"`, `model: "haiku"`): Analyzes branch for release readiness
   - **performance-analyst** (`subagent_type: "core:performance-analyst"`, `model: "haiku"`): Evaluates decision quality

   Pass to each agent:
   - Branch name and base branch as context
   - Repository URL (for changelog-writer)
   - List of archived tickets (for release-readiness and performance-analyst)
   - Git log main..HEAD (for performance-analyst)

   Wait for all 5 agents to complete.

   **Phase 2**: Invoke **story-writer** (`subagent_type: "core:story-writer"`, `model: "haiku"`):
   - Pass branch name and base branch
   - Pass release-readiness JSON output (for section 10)
   - Pass performance-analyst output (for section 9.2)

   Output locations:
   - `CHANGELOG.md`
   - `.workaholic/stories/<branch-name>.md`
   - `.workaholic/specs/**/*.md`
   - `.workaholic/terms/**/*.md`

   After all complete, stage all changes and commit: "Update documentation for PR"

   **Failure handling**: If any agent fails, report which succeeded and which failed. Continue with PR creation if story-writer succeeded (it's required for PR body).

4. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
5. **Push branch to remote**:
   ```bash
   git push -u origin <branch-name>
   ```
   This ensures the branch exists on remote before PR creation. The `-u` flag sets upstream tracking for new branches.
6. **Create or update PR** using the pr-creator subagent:

   Invoke the pr-creator subagent via Task tool with `subagent_type: "core:pr-creator"`, `model: "haiku"`:

   - Pass the branch name and base branch as context
   - The subagent handles: checking if PR exists, reading story file, deriving title, `gh` CLI operations
   - The subagent returns the PR URL (required for completion output)

## Completion Output (MANDATORY)

After creating or updating the PR, you **MUST** display the result:

- **New PR**: `PR created: <PR-URL>`
- **Updated PR**: `PR updated: <PR-URL>`

This URL display is **mandatory** - the command is NOT complete without it. The user needs the URL to review and share the PR.

