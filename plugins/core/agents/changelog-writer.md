---
name: changelog-writer
description: Update root CHANGELOG.md from archived tickets. Groups entries by category and links to commits and tickets.
tools: Read, Write, Edit, Bash, Glob, Grep
---

# Changelog Writer

Update root `CHANGELOG.md` with entries from archived tickets for the current branch.

## Input

You will receive:

- Branch name to generate changelog section for
- Repository URL for linking

## Instructions

### 1. Read Archived Tickets

Find all tickets archived for this branch:

```bash
ls -1 .workaholic/tickets/archive/<branch-name>/*.md 2>/dev/null
```

For each ticket, extract:

**From YAML frontmatter:**

- `commit_hash`: Short git hash for linking
- `category`: Added, Changed, or Removed

**From content:**

- Title from `# <Title>` heading
- First sentence from Overview section for description

### 2. Generate Changelog Entries

Format each entry as:

```markdown
- Title ([hash](repo-url/commit/full-hash)) - [ticket](path)
```

Where:

- `Title` is the ticket title (H1 heading)
- `hash` is the short commit hash from frontmatter
- `repo-url/commit/full-hash` links to the commit on GitHub
- `path` is the relative path to the archived ticket

### 3. Group by Category

Organize entries under category headings:

```markdown
### Added

- Entry 1
- Entry 2

### Changed

- Entry 3

### Removed

- Entry 4
```

Only include category sections that have entries.

### 4. Derive Issue URL

From branch name and remote:

- Extract issue number from branch (e.g., `i111-20260113-1832` → `111`)
- Convert remote URL to issue link
- Branch format: `i<issue>-<date>-<time>` or `feat-<date>-<time>` (no issue)

### 5. Update CHANGELOG.md

Add a new section at the top of the changelog (after any header):

```markdown
## [branch-name](issue-url)

### Added

- Entry 1

### Changed

- Entry 2
```

If no issue number exists in branch name, use just the branch name without link:

```markdown
## branch-name
```

### 6. Verify Structure

Ensure the changelog maintains proper structure:

- Title line at top: `# Changelog`
- Newest section first
- Blank lines between sections
- Consistent formatting

## Output

Return confirmation that:

- CHANGELOG.md was updated
- Number of entries added
- Categories included
