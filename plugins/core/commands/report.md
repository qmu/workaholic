---
name: report
description: Generate documentation (changelog, story, specs, terms) and create/update a pull request.
---

# Report

**Notice:** When user input contains `/report` - whether "run /report", "do /report", "update /report", or similar - they likely want this command.

Generate comprehensive documentation and create or update a pull request for the current branch.

The story file in `.workaholic/stories/<branch-name>.md` contains the complete PR description. Eleven sections: 1. Overview, 2. Motivation, 3. Journey, 4. Changes, 5. Outcome, 6. Historical Analysis, 7. Concerns, 8. Ideas, 9. Performance, 10. Release Preparation, 11. Notes.

This design makes stories the single source of truth for PR content, eliminating duplication between story generation and PR description assembly.

## Critical Behavior

- **ALWAYS display the PR URL** when finished (see Completion Output section)

## Instructions

1. Check the current branch name with `git branch --show-current`
2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
3. **Generate documentation and create PR** using story-moderator subagent:

   Invoke **story-moderator** (`subagent_type: "core:story-moderator"`, `model: "opus"`):
   - Pass branch name and base branch
   - Pass repository URL (for changelog-writer)
   - Pass list of archived tickets for the branch
   - Pass git log main..HEAD

   The story-moderator orchestrates documentation generation in two parallel groups:
   - Scanner group: changelog-writer, spec-writer, terms-writer
   - Story group (via story-writer): overview-writer, section-reviewer, release-readiness, performance-analyst
   - Story-writer writes the story file and invokes pr-creator
   - Returns confirmation with success/failure status and PR URL

   Output locations:
   - `CHANGELOG.md`
   - `.workaholic/stories/<branch-name>.md`
   - `.workaholic/specs/**/*.md`
   - `.workaholic/terms/**/*.md`

   After story-moderator completes, stage all changes and commit: "Update documentation for PR"

   **Failure handling**: If story-moderator reports agent failures, report which succeeded and which failed.

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

## Completion Output (MANDATORY)

After story-moderator completes, you **MUST** display the PR URL from its result:

- **New PR**: `PR created: <PR-URL>`
- **Updated PR**: `PR updated: <PR-URL>`

This URL display is **mandatory** - the command is NOT complete without it. The user needs the URL to review and share the PR.

