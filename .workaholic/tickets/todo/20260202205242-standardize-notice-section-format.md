---
created_at: 2026-02-02T20:52:42+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Standardize Notice Section Format Across Commands

## Overview

Apply a consistent "Notice:" format to the command recognition hints in all command files (ticket.md, drive.md, story.md), replacing the current blockquote format with a more explicit labeled format.

## Key Files

- `plugins/core/commands/ticket.md` - Source of the target "Notice:" format
- `plugins/core/commands/drive.md` - Currently uses blockquote format
- `plugins/core/commands/story.md` - Currently uses blockquote format

## Related History

No past tickets have directly addressed command file formatting conventions.

## Implementation Steps

1. Define the standardized "Notice:" format pattern:
   - Format: `**Notice:** <hint text>`
   - Example: `**Notice:** When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.`

2. Update `plugins/core/commands/ticket.md`:
   - Change line 8 from blockquote `> When user input...` to `**Notice:** When user input...`

3. Update `plugins/core/commands/drive.md`:
   - Change line 13 from blockquote `> When user input...` to `**Notice:** When user input...`

4. Update `plugins/core/commands/story.md`:
   - Change line 8 from blockquote `> When user input...` to `**Notice:** When user input...`

## Considerations

- The "Notice:" label makes the purpose of the hint more explicit than a plain blockquote
- This is a cosmetic/consistency change with no functional impact on command behavior
- All three commands should be updated in the same commit for consistency
