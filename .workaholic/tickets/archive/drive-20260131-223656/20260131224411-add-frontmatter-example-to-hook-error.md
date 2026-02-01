---
created_at: 2026-01-31T22:44:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: d5a432a
category: Changed
---

# Point Hook Errors to create-ticket Skill

## Overview

When the ticket validation hook rejects a ticket due to format errors, Claude often tries to fix it by guessing instead of consulting the authoritative source. The `create-ticket` skill already documents the correct format comprehensively - the hook just needs to point there.

Currently hook errors say "Error: X must be Y" but don't tell Claude where to find the complete specification. Adding a reference to the skill file in error output guides Claude to the correct source rather than duplicating documentation in error messages.

## Key Files

- `plugins/core/hooks/validate-ticket.sh` - Validation hook (add skill reference to errors)
- `plugins/core/skills/create-ticket/SKILL.md` - Authoritative format documentation (no changes)

## Related History

Historical tickets reveal iterative improvements to ticket format documentation and validation:

- [20260131192546-improve-create-ticket-frontmatter-clarity.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192546-improve-create-ticket-frontmatter-clarity.md) - Improved skill clarity with examples and common mistakes
- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Implemented the validation hook

## Implementation Steps

1. **Add skill reference helper function** at the top of validate-ticket.sh (after shebang):

   ```bash
   print_skill_reference() {
     echo "See: plugins/core/skills/create-ticket/SKILL.md" >&2
   }
   ```

2. **Append skill reference to all exit points** - For each error that exits, add `print_skill_reference` before `exit`:

   - After `created_at` missing error (around line 78)
   - After `created_at` format error (around line 85)
   - After `author` missing error (around line 93)
   - After `author` format error (around line 99)
   - After `effort` format error (around line 140)
   - After `layer` format error (around line 117)

## Considerations

- Single source of truth: skill file is authoritative, hook just points to it
- No duplication: error messages stay concise, skill has all details
- Maintenance: changing format only requires updating the skill, not hook messages
