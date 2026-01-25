---
date: 2026-01-25
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.1h
commit_hash: c82b53e
category: Changed
---

# Change ticket date field to datetime format

## Overview

The `date` field in ticket YAML frontmatter currently uses date-only format (`YYYY-MM-DD`), but datetime format (`YYYY-MM-DDTHH:MM:SS+TZ`) would be more precise and consistent with other Workaholic artifacts. Stories already use ISO 8601 datetime for `started_at` and `ended_at`. Using datetime for tickets enables precise creation time tracking and aligns with the timestamp already embedded in ticket filenames.

## Key Files

- `plugins/core/commands/ticket.md` - Update the frontmatter specification and date command
- `.work/terminology/artifacts.md` - Update ticket metadata description
- `.work/terminology/artifacts_ja.md` - Japanese translation

## Implementation Steps

1. **Update ticket.md frontmatter specification** (section 5):

   Change the template from:
   ```yaml
   date: YYYY-MM-DD
   ```

   To:
   ```yaml
   created_at: YYYY-MM-DDTHH:MM:SS+TZ
   ```

2. **Update the date command** in the Frontmatter Fields section:

   Change from:
   ```
   - `date`: Current date in ISO format. Use `date +%Y-%m-%d`
   ```

   To:
   ```
   - `created_at`: Creation timestamp in ISO 8601 format. Use `date -Iseconds`
   ```

3. **Update artifacts.md terminology**:

   Change the ticket metadata description from:
   ```
   - `date`: Creation date (ISO format)
   ```

   To:
   ```
   - `created_at`: Creation timestamp (ISO 8601 datetime)
   ```

4. **Update artifacts_ja.md** with the same change (Japanese translation)

## Considerations

- **Field rename**: Changing from `date` to `created_at` follows the `_at` naming convention used for timestamps in stories (`started_at`, `ended_at`). This is clearer than `date` which could be ambiguous.
- **Backward compatibility**: Existing tickets with `date` field will still be readable, but new tickets will use `created_at`. This is acceptable since archived tickets are historical records.
- **Command simplicity**: `date -Iseconds` is a single command that outputs ISO 8601 with timezone, cleaner than building the format manually.

## Final Report

Development completed as planned.
