---
name: pull-request
description: Create or update a pull request with a summary focused on why changes were made.
---

# Pull Request

Create or update a pull request for the current branch.

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
   - **terminology-writer** (`subagent_type: "core:terminology-writer"`): Updates `.workaholic/terminology/` with new terms

   Pass to each agent:
   - Branch name and base branch as context
   - Repository URL (for changelog-writer)

   Wait for all 4 agents to complete. Each writes to different locations:
   - `CHANGELOG.md`
   - `.workaholic/stories/<branch-name>.md`
   - `.workaholic/specs/**/*.md`
   - `.workaholic/terminology/**/*.md`

   After all complete, stage all changes and commit: "Update documentation for PR"

   **Failure handling**: If any agent fails, report which succeeded and which failed. Continue with PR creation if story-writer succeeded (it's required for PR body).

5. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
6. Check if a PR already exists for this branch:
   ```sh
   gh pr list --head $(git branch --show-current) --json number,title,url
   ```
7. **Read story file and prepare PR content**:
   - Read `.workaholic/stories/<branch-name>.md`
   - Strip YAML frontmatter (everything between `---` delimiters)
   - The remaining content IS the PR body
8. **Derive PR title from Summary section**:
    - Parse the Summary section from the story
    - If single change: use that change as title (e.g., "Add dark mode toggle")
    - If multiple changes: use first change + "etc" (e.g., "Add dark mode toggle etc")
    - Keep title concise (GitHub truncates long titles)

## Creating vs Updating

The story file content (minus YAML frontmatter) IS the PR body.

### If NO PR exists:

```sh
gh pr create --title "<derived-title>" --body "$(cat <<'EOF'
<story content without frontmatter>
EOF
)"
```

### If PR already exists:

Update the PR using `gh pr edit` with the story file:

```sh
gh pr edit <number> --title "<derived-title>" --body-file .workaholic/stories/<branch-name>.md
```

Note: The `--body-file` flag reads the file directly, so strip the YAML frontmatter from the story file first, or use a temporary file without frontmatter.

## Completion Output (MANDATORY)

After creating or updating the PR, you **MUST** display the result:

- **New PR**: `PR created: <PR-URL>`
- **Updated PR**: `PR updated: <PR-URL>`

This URL display is **mandatory** - the command is NOT complete without it. The user needs the URL to review and share the PR.

