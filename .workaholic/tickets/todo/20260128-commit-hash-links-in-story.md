---
title: Add GitHub links to commit hashes in story Changes section
category: Enhance
layer: Skill
---

## Overview

Commit hashes in the story Changes section (section 4) are currently plain text. They should be clickable GitHub links for easy navigation to the actual commit.

## Current State

In `plugins/core/skills/write-story/SKILL.md`, the Changes section template shows:

```markdown
### 4.1. <Ticket title> (hash)
```

This produces plain text hashes like `(e1dcf1f)` in the generated story.

## Desired State

Commit hashes should be GitHub links:

```markdown
### 4.1. <Ticket title> ([hash](https://github.com/qmu/workaholic/commit/full-hash))
```

This produces clickable links like `([e1dcf1f](https://github.com/qmu/workaholic/commit/e1dcf1f...))`.

## Implementation

### File to Modify

`plugins/core/skills/write-story/SKILL.md`

### Changes

1. Update the Changes section template (around line 96-114) to show the linked format:

   **Before:**
   ```markdown
   ### 4.1. <Ticket title> (hash)
   ```

   **After:**
   ```markdown
   ### 4.1. <Ticket title> ([hash](https://github.com/qmu/workaholic/commit/hash))
   ```

2. Update the Changes Guidelines to reflect the new format:

   **Before:**
   ```markdown
   - Format: `### 4.N. <Title> (hash)` - use plain hash, not a link
   ```

   **After:**
   ```markdown
   - Format: `### 4.N. <Title> ([hash](https://github.com/qmu/workaholic/commit/hash))` - link to GitHub commit
   ```

## Notes

- Use the short hash for display text but the full hash in the URL works with either
- The repository URL `https://github.com/qmu/workaholic` is hardcoded since this is a single-repo project
- This aligns with existing markdown linking conventions established in general rules
