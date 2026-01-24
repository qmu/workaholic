---
name: pull-request
description: Create or update a pull request with a summary focused on why changes were made.
---

# Pull Request

Create or update a pull request for the current branch.

## Instructions

1. Check the current branch name with `git branch --show-current`
2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
3. **Check for remaining tickets**:
   - List files in `.work/tickets/*.md` (excluding README.md)
   - If any tickets exist:
     - Warn the user: "Found X unfinished ticket(s) that will be moved to icebox:"
     - List the ticket filenames
     - Create `.work/tickets/icebox/` if it doesn't exist
     - Move each ticket to `.work/tickets/icebox/`
     - Stage and commit: "Move remaining tickets to icebox"
   - If no tickets, continue with normal PR flow
4. **Consolidate branch CHANGELOG to root**:
   - Read `.work/changelogs/<branch-name>.md` if it exists
   - Read existing `CHANGELOG.md` (root)
   - Merge branch entries into root CHANGELOG under branch section header
   - Format: `## [<branch-name>](issue-url)`
   - Reorganize: deduplicate, sort by category, combine related entries
   - Write updated root `CHANGELOG.md`
   - Stage and commit: "Update CHANGELOG for PR"
5. **Sync documentation**:
   - Run `/sync-src-doc` to update `.work/specs/` and `.work/terminology/`
   - Stage and commit: "Sync documentation for PR"
6. **Generate branch story** in `.work/stories/<branch-name>.md`:

   The story serves as the single source of truth for PR content. It contains the complete PR description that will be copied to GitHub.

   **Gather source data:**

   Read archived tickets for this branch:

   ```bash
   ls -1 .work/tickets/archive/<branch-name>/*.md 2>/dev/null
   ```

   Read CHANGELOG entries for this branch:

   - Parse root `CHANGELOG.md` for the section matching the current branch
   - Collect entries from all subsections (Added, Changed, Removed)
   - Each entry has format: `- Title ([hash](url)) - [ticket](file.md)`
   - Entries may include a description line explaining the WHY

   For each ticket, extract:

   - **Overview section**: The "why" - motivation and problem description
   - **Final Report section**: The "how" - what actually happened, including deviations

   **Calculate performance metrics:**

   ```bash
   # Get commit count for this branch
   git rev-list --count main..HEAD

   # Get first and last commit timestamps (ISO 8601 format)
   git log main..HEAD --reverse --format=%cI | head -1
   git log main..HEAD --format=%cI | head -1

   # Calculate duration in hours between first and last commit
   # velocity = commits / duration_hours (handle 0 duration as 1 hour minimum)
   ```

   **Derive issue URL** from branch name and remote:

   - Extract issue number from branch (e.g., `i111-20260113-1832` → `111`)
   - Convert remote URL to issue link for reference in PR
   - Branch format: `i<issue>-<date>-<time>` or `feat-<date>-<time>` (no issue)

   **Create story file with YAML frontmatter:**

   ```yaml
   ---
   branch: <branch-name>
   started_at: YYYY-MM-DDTHH:MM:SS+TZ # from first commit timestamp
   ended_at: YYYY-MM-DDTHH:MM:SS+TZ # from last commit timestamp
   tickets_completed: <count>
   commits: <count>
   duration_hours: <number> # time between first and last commit
   velocity: <commits per hour, rounded to 1 decimal>
   ---
   ```

   **Story content structure (this IS the PR description):**

   ```markdown
   Refs #<issue-number>

   ## Summary

   1. First meaningful change (from CHANGELOG entry titles)
   2. Second meaningful change (from CHANGELOG entry titles)
   3. ...

   ## Motivation

   [Synthesize the "why" from ticket Overviews. What problem or opportunity started this work? Write as a narrative, not a list.]

   ## Journey

   [Describe the progression of work. What was planned? What unexpected challenges arose? How were decisions made? Draw from Final Reports to capture deviations and learnings.]

   ## Changes

   ### 1. First meaningful change

   Detailed explanation from CHANGELOG description. Why this was needed and what it solves.

   ### 2. Second meaningful change

   Detailed explanation from CHANGELOG description. Why this was needed and what it solves.

   ## Outcome

   [Summarize what was accomplished. Reference key tickets for details.]

   ## Performance

   **Metrics**: <commits> commits over <duration> hours (<velocity> commits/hour)

   ### Pace Analysis

   [Quantitative reflection on development pace - was velocity consistent or varied? Were commits small and focused or large? Any patterns in timing?]

   ### Decision Review

   [Invoke the performance-analyst subagent with:

   - Archived tickets for this branch
   - Git log (main..HEAD)
   - Performance metrics from frontmatter

   Include the subagent's output here.]

   ## Notes

   Additional context for reviewers or future reference.
   ```

   **Writing guidelines:**

   - Write in third person ("The developer discovered..." not "I discovered...")
   - Connect tickets into a narrative arc, not a list
   - Highlight decision points and trade-offs
   - Keep Motivation/Journey/Outcome concise (aim for 200-400 words total)
   - Changes section can be longer to explain each change fully

   **Update .work/stories/README.md** to include the new story:

   - Add entry: `- [<branch-name>.md](<branch-name>.md) - Brief description of the branch work`

   Stage and commit: "Generate branch story"

7. **Format changed files** (silent step):
   - Run project linter/formatter on changed files
   - Do NOT announce "reading file again" or similar verbose messages
   - Just silently format and continue
   - Stage and commit any formatting changes: "Format code"
8. Check if a PR already exists for this branch:
   ```sh
   gh pr list --head $(git branch --show-current) --json number,title,url
   ```
9. **Read story file and prepare PR content**:
   - Read `.work/stories/<branch-name>.md`
   - Strip YAML frontmatter (everything between `---` delimiters)
   - The remaining content IS the PR body
10. **Derive PR title from Summary section**:
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

Use `gh api` to update the PR title and body:

```sh
gh api repos/{owner}/{repo}/pulls/<number> -X PATCH \
  -f title="<derived-title>" \
  -f body="$(cat <<'EOF'
<story content without frontmatter>
EOF
)"
```

## Story as PR Description

The story file in `.work/stories/<branch-name>.md` contains the complete PR description. Seven sections: Summary, Motivation, Journey, Changes, Outcome, Performance, Notes.

This design makes stories the single source of truth for PR content, eliminating duplication between story generation and PR description assembly.
