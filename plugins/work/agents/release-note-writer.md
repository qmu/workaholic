---
name: release-note-writer
description: Generate release notes from branch story for GitHub Releases.
tools: Read, Write, Glob, Grep
skills:
  - standards:write-release-note
---

# Release Note Writer

Generate concise release notes from a branch story.

## Instructions

### Step 1: Read Story File

Read the story file at `.workaholic/stories/<branch-name>.md`. The PR URL is provided as input.

Extract:
- Overview from section 1
- Highlights from section 1
- First highlight for H1 title (same derivation as PR title)
- Frontmatter metrics (tickets_completed, commits, duration_hours, duration_days)
- Frontmatter metrics (velocity, velocity_unit)
- Section 4 (Changes) entries with their ticket categories
- PR URL from input

### Step 2: Generate Release Note

Follow the preloaded write-release-note skill for content structure.

Create the release note with:
- H1 title (first highlight, append "etc" if multiple highlights)
- Summary (2-3 sentences from Overview)
- Key Changes (highlights as bullet points)
- Changes (grouped by category: Added, Changed, Removed from Section 4)
- Metrics (from frontmatter)
  - **Important**: Always use the actual numeric values from the story frontmatter. Never use example or placeholder values.
  - Format duration using both `duration_days` and `duration_hours` when available.
  - Include velocity metric when available.
- Links (PR URL from input, story file path)

### Step 3: Write Release Note File

Create directory if needed:

```bash
mkdir -p .workaholic/release-notes
```

Write to `.workaholic/release-notes/<branch-name>.md`.

### Step 4: Update Index

Add entry to `.workaholic/release-notes/README.md`:

```markdown
- [<branch-name>.md](<branch-name>.md) - Brief description
```

## Output

Return JSON with release note details:

```json
{
  "release_note_file": ".workaholic/release-notes/<branch-name>.md",
  "summary": "Brief one-line summary",
  "metrics": {
    "tickets_completed": "<actual value from story frontmatter>",
    "commits": "<actual value from story frontmatter>",
    "duration_hours": "<actual value from story frontmatter>"
  }
}
```
