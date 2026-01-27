---
created_at: 2026-01-28T00:56:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: XS
commit_hash: 93a1127
category: Added
---

# Add rule for linking markdown files when mentioned

## Overview

When writing markdown documentation, file references should be clickable links rather than plain text or backticks. This is especially important for stable documentation (specs, terms, stories) that readers may want to navigate to directly.

Add a rule to `general.md` that instructs Claude to use markdown links when referencing `.md` files, particularly in documentation contexts.

## Key Files

- `plugins/core/rules/general.md` - Add markdown linking guideline

## Related History

The previous ticket established linking for archived tickets specifically; this extends the pattern to all markdown files.

Past tickets that touched similar areas:

- [20260128005204-link-archived-tickets-in-related-history.md](.workaholic/tickets/archive/feat-20260128-001720/20260128005204-link-archived-tickets-in-related-history.md) - Added linking for archived tickets (same concern)
- [20260124120108-enforce-i18n-readme-links.md](.workaholic/tickets/archive/feat-20260124-105903/20260124120108-enforce-i18n-readme-links.md) - Established README link mirroring (same layer: Config)

## Implementation Steps

1. **Add linking rule to general.md** (`plugins/core/rules/general.md`):
   ```markdown
   - **Link markdown files when referenced** - When mentioning `.md` files in documentation, use markdown links: `[filename.md](path/to/file.md)` not just backticks. Especially important for stable docs (specs, terms, stories).
   ```

## Considerations

- This applies to documentation contexts, not necessarily code comments
- Stable locations (`.workaholic/specs/`, `.workaholic/terms/`) benefit most from linking
- Tickets in `todo/` may move to `archive/` so links should be used when the location is known
- Links should use repository-relative paths

## Final Report

Added markdown linking rule to general.md as the third rule in the General Rules list. The rule instructs Claude to use markdown links when mentioning .md files in documentation for better navigability.
