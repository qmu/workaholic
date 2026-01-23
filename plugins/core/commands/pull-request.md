---
name: pull-request
description: Create or update a pull request with a summary focused on why changes were made.
---

# Pull Request

Create or update a pull request for the current branch.

## Instructions

1. Check the current branch name with `git branch --show-current`
2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
3. **Consolidate branch CHANGELOG to root**:
   - Read `doc/changelogs/<branch-name>.md` if it exists
   - Read existing `CHANGELOG.md` (root)
   - Merge branch entries into root CHANGELOG under branch section header
   - Format: `## [<branch-name>](issue-url)`
   - Reorganize: deduplicate, sort by category, combine related entries
   - Write updated root `CHANGELOG.md`
   - Stage and commit: "Update CHANGELOG for PR"
4. **Update documentation in `doc/specs/`**:
   - Read all archived tickets from `doc/tickets/archive/<branch-name>/`
   - Analyze cumulative changes across all tickets in the branch
   - Update `doc/specs/` following the doc-specs rule (auto-loaded for that path)
   - Stage and commit: "Update documentation for PR"
5. **Generate branch story** in `doc/stories/<branch-name>.md`:

   Read all archived tickets for this branch:
   ```bash
   ls -1 doc/tickets/archive/<branch-name>/*.md 2>/dev/null
   ```

   For each ticket, extract:
   - **Overview section**: The "why" - motivation and problem description
   - **Final Report section**: The "how" - what actually happened, including deviations

   Create story file with YAML frontmatter:
   ```yaml
   ---
   branch: <branch-name>
   started: YYYY-MM-DD  # from first ticket timestamp
   last_updated: YYYY-MM-DD  # today
   tickets_completed: <count>
   ---
   ```

   Story content structure:
   ```markdown
   # Story: <Branch Name>

   ## Motivation

   [Synthesize the "why" from ticket Overviews. What problem or opportunity started this work? Write as a narrative, not a list.]

   ## Journey

   [Describe the progression of work. What was planned? What unexpected challenges arose? How were decisions made? Draw from Final Reports to capture deviations and learnings.]

   ## Outcome

   [Summarize what was accomplished. Reference key tickets for details.]
   ```

   **Writing guidelines:**
   - Write in third person ("The developer discovered..." not "I discovered...")
   - Connect tickets into a narrative arc, not a list
   - Highlight decision points and trade-offs
   - Keep it concise (aim for 200-400 words)

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
8. **Read CHANGELOG entries for this branch** (primary source for both summary and details):
   - Parse root `CHANGELOG.md` for the section matching the current branch
   - Collect bullets from all subsections (Added, Changed, Removed)
   - Each entry has format: `- Title ([hash](url)) - [ticket](file.md)`
   - Entries may include a second line with description explaining the WHY
   - Use entry titles for numbered Summary list
   - Use descriptions for detailed Changes section explanations
   - If CHANGELOG section doesn't exist, fall back to git log
9. **Derive issue URL** from branch name and remote:
   - Extract issue number from branch (e.g., `i111-20260113-1832` → `111`)
   - Convert remote URL to issue link for reference in PR
10. Generate PR description:
   - Title: Concise summary of the overall change
   - Summary list: Use CHANGELOG entry titles as the numbered list
   - Changes section: Use CHANGELOG entry descriptions to explain the WHY
   - Reference the linked issue from branch name

## Creating vs Updating

Use heredoc for multi-line descriptions:

### If NO PR exists:

```sh
gh pr create --title "Title" --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

### If PR already exists:

Use `gh api` to update the PR title and body (avoids Projects classic deprecation error):

1. **Derive title from CHANGELOG**:

   - Parse CHANGELOG entries for this branch
   - If single change: use that change as title (e.g., "Add dark mode toggle")
   - If multiple changes: use first change + "etc" (e.g., "Add dark mode toggle etc")
   - Keep title concise (GitHub truncates long titles)

2. **Update with `gh api`**:

```sh
gh api repos/{owner}/{repo}/pulls/<number> -X PATCH \
  -f title="<derived-title>" \
  -f body="$(cat <<'EOF'
## Summary
...
EOF
)"
```

## PR Description Format

Four headings: Summary, Story, Changes, Notes.

```markdown
Refs #<issue-number>

## Summary

1. First meaningful change (from CHANGELOG)
2. Second meaningful change (from CHANGELOG)
3. Third meaningful change (from CHANGELOG)

## Story

[Include Motivation and Journey sections from doc/stories/<branch>.md - the narrative of what problem existed, how the work progressed, and what decisions were made along the way.]

## Changes

### 1. First meaningful change

Detailed explanation of why this was needed and what it solves. (from CHANGELOG description)

### 2. Second meaningful change

Detailed explanation of why this was needed and what it solves. (from CHANGELOG description)

## Notes

Additional context for reviewers or future reference.
```

### Deriving Issue Number and URL

- Branch format: `i<issue>-<date>-<time>` (e.g., `i111-20260113-1832`)
- Extract issue number: `111`
- Remote URL: `git remote get-url origin`
- Convert to issues URL:
  - `git@github.com:owner/repo.git` → `https://github.com/owner/repo/issues/111`
  - `https://github.com/owner/repo.git` → `https://github.com/owner/repo/issues/111`
