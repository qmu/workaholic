---
name: release-note-writer
description: Generate release notes from branch story for GitHub Releases.
tools: Read, Write, Glob, Grep
skills:
  - write-release-note
---

# Release Note Writer

Generate concise release notes from a branch story.

## Instructions

### Step 1: Read Story File

Read the story file at `.workaholic/stories/<branch-name>.md`.

Extract:
- Overview from section 1
- Highlights from section 1
- Frontmatter metrics (tickets_completed, commits, duration_hours)

### Step 2: Generate Release Note

Follow the preloaded write-release-note skill for content structure.

Create the release note with:
- Summary (2-3 sentences from Overview)
- Key Changes (highlights as bullet points)
- Metrics (from frontmatter)
- Links (PR URL if available, story file path)

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
    "tickets_completed": 6,
    "commits": 12,
    "duration_hours": 1.0
  }
}
```
