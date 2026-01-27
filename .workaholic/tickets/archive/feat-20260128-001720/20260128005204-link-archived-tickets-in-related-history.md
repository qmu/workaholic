---
created_at: 2026-01-28T00:52:04+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: XS
commit_hash: 6d03f2c
category: Changed
---

# Link archived tickets in Related History section

## Overview

Currently the Related History section in tickets lists filenames in backticks but they're not clickable. Change to use markdown links with full paths so readers can navigate directly to referenced tickets.

Current format:
```markdown
- `20260127010716-rename-terminology-to-terms.md` - Description
```

New format:
```markdown
- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/feat-20260126-214833/20260127010716-rename-terminology-to-terms.md) - Description
```

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Update Related History format example and instructions

## Related History

The Related History feature was added to help developers understand past context when working on similar areas.

Past tickets that touched similar areas:

- [20260127101903-add-related-history-to-tickets.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101903-add-related-history-to-tickets.md) - Added Related History section to ticket format (same file)

## Implementation Steps

1. **Update create-ticket skill** (`plugins/core/skills/create-ticket/SKILL.md`):
   - Update the File Structure template to show linked format
   - Update the Finding Related History section to specify link format
   - Add note: "Use full path from repository root for links"

2. **Example format to document**:
   ```markdown
   ## Related History

   <summary>

   Past tickets that touched similar areas:

   - [filename.md](full/path/to/archived/ticket.md) - Description (match reason)
   ```

## Considerations

- Links use repository-relative paths starting with `.workaholic/`
- The branch directory name is needed in the path (e.g., `feat-20260126-214833`)
- When searching for related tickets, the full path is already available from the search results
- This makes tickets more navigable in GitHub's markdown preview

## Final Report

Updated create-ticket skill with linked format for Related History section. Changed File Structure template to show markdown link syntax with repository-relative paths. Added Link format subsection in Finding Related History with explicit format example and note about including branch directory from search results.
