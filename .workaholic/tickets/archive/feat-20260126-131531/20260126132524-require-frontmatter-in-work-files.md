---
created_at: 2026-01-26T13:25:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 30214da
category: Changed
---

# Require Frontmatter in Work Directory Files

## Overview

Add a rule requiring all markdown files under `.workaholic/` to have YAML frontmatter with at least `author` (git email), `created_at`, and `modified_at` (ISO timestamp) fields. This ensures traceability for all working artifacts.

## Key Files

- `plugins/core/rules/workaholic.md` - Add the frontmatter requirement rule (path already targets `.workaholic/**/*`)

## Implementation Steps

1. Add a new rule section to `plugins/core/rules/general.md` titled "Work Directory Frontmatter Requirements"

2. The rule should specify minimum required fields:
   ```yaml
   ---
   author: <git user.email>
   created_at: <ISO 8601 timestamp>
   modified_at: <ISO 8601 timestamp>
   ---
   ```

3. The rule should instruct Claude to:
   - Always include these fields when creating new files in `.workaholic/`
   - Update `modified_at` when editing existing files
   - Use `git config user.email` for `author` field
   - Use `date -Iseconds` for `modified_at` field (ISO 8601 datetime with timezone)

4. Document that additional fields are allowed and encouraged per subdirectory:
   - `specs/`: `title`, `description`, `category`, `commit_hash`
   - `stories/`: `branch`, `started_at`, `ended_at`, metrics fields
   - `terminology/`: `title`, `description`, `category`
   - `tickets/`: `created_at`, `type`, `layer`, `effort`, etc.

5. Note that `tickets/` already has its own frontmatter schema defined in `ticket.md` command - the rule should reference that existing schema rather than override it

## Considerations

- This is forward-looking - existing files without frontmatter don't need immediate migration
- The `author` field tracks who last modified, not original creator (use `created_by` if needed)
- `modified_at` should be updated on every edit, not just creation
- README files are exempt from the `author` requirement since they're project-level docs

## Final Report

Development completed as planned.
