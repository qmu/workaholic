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
   - Read `doc/tickets/archive/<branch-name>/CHANGELOG.md` if it exists
   - Read existing `CHANGELOG.md` (root)
   - Merge branch entries into root CHANGELOG under branch section header
   - Format: `## [<branch-name>](issue-url)`
   - Reorganize: deduplicate, sort by category, combine related entries
   - Write updated root `CHANGELOG.md`
   - Stage and commit: "Update CHANGELOG for PR"
4. Check if a PR already exists for this branch:
   ```sh
   gh pr list --head $(git branch --show-current) --json number,title,url
   ```
5. **Read CHANGELOG entries for this branch** (primary source for summary):
   - Parse root `CHANGELOG.md` for the section matching the current branch
   - Collect bullets from all subsections (Added, Changed, Removed)
   - These combined bullets become the numbered Summary list
   - If CHANGELOG section doesn't exist, fall back to git log
6. Get commit details for the "Changes" section:
   ```sh
   git log main..HEAD --pretty=format:"- %s%n%b" --reverse
   ```
7. **Extract the WHY from commit bodies**:
   - The commit body contains the actual reasoning and context
   - Titles are just summaries - the body explains WHY
   - Extract the motivation from each commit's body text
   - Group related changes together based on their purpose
8. **Derive issue URL** from branch name and remote:
   - Extract issue number from branch (e.g., `i111-20260113-1832` → `111`)
   - Convert remote URL to issue link for reference in PR
9. Generate PR description:
   - Title: Concise summary of the overall change
   - Summary list: Use CHANGELOG entries as the numbered list
   - Changes section: Explain the WHY using commit body details
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

Only three headings: Summary, Changes, Notes.

```markdown
Refs #<issue-number>

## Summary

[Motivation paragraph: What problem existed and why this work was needed. Write for someone unfamiliar with the context.]

1. First meaningful change (from CHANGELOG)
2. Second meaningful change (from CHANGELOG)
3. Third meaningful change (from CHANGELOG)

## Changes

### 1. First meaningful change

Detailed explanation of why this was needed and what it solves. (from commit body)

### 2. Second meaningful change

Detailed explanation of why this was needed and what it solves. (from commit body)

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
