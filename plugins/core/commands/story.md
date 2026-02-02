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
3. **Generate documentation** using story-writer subagent:

   Invoke **story-writer** (`subagent_type: "core:story-writer"`):
   - Pass branch name and base branch
   - Pass repository URL (for changelog-writer)
   - Pass list of archived tickets for the branch
   - Pass git log main..HEAD

   The story-writer orchestrates all documentation agents internally:
   - Invokes 6 agents in parallel (changelog, spec, terms, release-readiness, performance, overview)
   - Integrates their outputs into the story file
   - Returns confirmation with success/failure status

   Output locations:
   - `CHANGELOG.md`
   - `.workaholic/stories/<branch-name>.md`
   - `.workaholic/specs/**/*.md`
   - `.workaholic/terms/**/*.md`

   After story-writer completes, stage all changes and commit: "Update documentation for PR"

   **Failure handling**: If story-writer reports agent failures, report which succeeded and which failed. Continue with PR creation if story file was created (required for PR body).

4. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
5. **Bump version** following CLAUDE.md Version Management section
6. **Push branch to remote**:
   ```bash
   git push -u origin <branch-name>
   ```
   This ensures the branch exists on remote before PR creation. The `-u` flag sets upstream tracking for new branches.
7. **Create or update PR** using the pr-creator subagent:

   Invoke the pr-creator subagent via Task tool with `subagent_type: "core:pr-creator"`, `model: "haiku"`:

   - Pass the branch name and base branch as context
   - The subagent handles: checking if PR exists, reading story file, deriving title, `gh` CLI operations
   - The subagent returns the PR URL (required for completion output)

## Completion Output (MANDATORY)

After creating or updating the PR, you **MUST** display the result:

- **New PR**: `PR created: <PR-URL>`
- **Updated PR**: `PR updated: <PR-URL>`

This URL display is **mandatory** - the command is NOT complete without it. The user needs the URL to review and share the PR.

