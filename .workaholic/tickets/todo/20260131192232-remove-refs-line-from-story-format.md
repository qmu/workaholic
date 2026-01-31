---
created_at: 2026-01-31T19:22:32+09:00
author: a@qmu.jp
type: housekeeping
layer: Config
effort: 0.1h
---

# Remove Refs Line from Story and PR Format

## Overview

Remove the `Refs #<issue-number>` line from story files and PR descriptions. The current format includes a fake issue reference that doesn't exist, adding noise to PR descriptions. Stories should start directly with `## 1. Overview` after the YAML frontmatter.

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Story content structure template (remove Refs line)

## Implementation

1. Edit `write-story/SKILL.md`:
   - Remove `Refs #<issue-number>` from the "Story Content Structure" section
   - Update the template to show content starting with `## 1. Overview` immediately after frontmatter description

## Related History

- `20260124005056-story-as-pr-description.md` - Refactored story to be PR description, established current 11-section structure
- `20260131153043-allow-skill-to-skill-nesting.md` - Enhanced write-story with skill composition

## Out of Scope

- Changing section numbering or content
- Modifying `create-or-update.sh` (already just strips frontmatter)
- Adding real GitHub issue linking (separate feature if desired)
