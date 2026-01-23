# Rename Story Datetime Fields

## Overview

Rename the story frontmatter fields `started` and `last_updated` to `started_at` and `ended_at`, and change their format from date (`YYYY-MM-DD`) to datetime (`YYYY-MM-DDTHH:MM:SS`). This provides more precise timing information for performance analysis and follows the `_at` naming convention common for timestamp fields.

## Key Files

- `plugins/core/commands/pull-request.md` - Update story generation instructions
- `doc/stories/feat-20260123-032323.md` - Update existing story file

## Implementation Steps

1. **Update `plugins/core/commands/pull-request.md`** step 5 (Generate branch story):

   Change the YAML frontmatter specification from:

   ```yaml
   started: YYYY-MM-DD # from first ticket timestamp
   last_updated: YYYY-MM-DD # today
   ```

   To:

   ```yaml
   started_at: YYYY-MM-DDTHH:MM:SS # from first commit timestamp
   ended_at: YYYY-MM-DDTHH:MM:SS # from last commit timestamp
   ```

2. **Update git commands** to extract datetime instead of date:

   ```bash
   # Get first commit datetime (ISO format)
   git log main..HEAD --reverse --format=%cI | head -1

   # Get last commit datetime (ISO format)
   git log main..HEAD --format=%cI | head -1
   ```

   Note: `%cI` gives ISO 8601 format with timezone, `%ci` gives similar without T separator. Use `%cI` for proper ISO format.

3. **Update `doc/stories/feat-20260123-032323.md`**:

   Change:

   ```yaml
   started: 2026-01-23
   last_updated: 2026-01-23
   ```

   To (with actual timestamps from git history):

   ```yaml
   started_at: 2026-01-23T12:06:08+09:00
   ended_at: 2026-01-23T16:14:28+09:00
   ```

## Considerations

- `ended_at` is more accurate than `last_updated` since it marks when the branch work concluded, not when the story file was edited
- The `_at` suffix is a common convention indicating a timestamp field
- ISO 8601 datetime format is unambiguous and sortable
- Existing stories need migration (only one currently exists)
- This change complements the performance metrics ticket - precise timestamps enable accurate duration calculation

## Final Report

Development completed as planned.
