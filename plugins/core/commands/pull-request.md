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
4. **Update root CHANGELOG from archived tickets**:
   - Read all tickets from `.workaholic/tickets/archive/<branch-name>/*.md`
   - For each ticket, extract from frontmatter: `commit_hash`, `category`
   - Extract title from `# <Title>` heading
   - Extract first sentence from Overview section for description
   - Get repo URL from git remote
   - Generate entries in format: `- Title ([hash](url)) - [ticket](path)`
   - Group entries by category (Added, Changed, Removed)
   - Add branch section to root `CHANGELOG.md`: `## [<branch-name>](issue-url)`
   - Stage and commit: "Update CHANGELOG for PR"
5. **Generate branch story** using the story-writer subagent:

   Invoke the story-writer subagent via Task tool with `subagent_type: "core:story-writer"`:

   - Pass the branch name and base branch as context
   - The subagent handles: reading archived tickets, calculating metrics, generating story file, invoking performance-analyst
   - The story file is created at `.workaholic/stories/<branch-name>.md`

   Stage and commit: "Generate branch story"

6. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
7. Check if a PR already exists for this branch:
   ```sh
   gh pr list --head $(git branch --show-current) --json number,title,url
   ```
8. **Read story file and prepare PR content**:
   - Read `.workaholic/stories/<branch-name>.md`
   - Strip YAML frontmatter (everything between `---` delimiters)
   - The remaining content IS the PR body
9. **Derive PR title from Summary section**:
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

