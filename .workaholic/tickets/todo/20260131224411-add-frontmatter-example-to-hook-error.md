---
created_at: 2026-01-31T22:44:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Correct Frontmatter Example to Hook Error Messages

## Overview

When Claude writes a ticket with wrong frontmatter format (e.g., `date:` instead of `created_at:`, `effort: S` instead of empty), the validation hook correctly blocks the operation but only shows what was wrong - not how to fix it. Claude then attempts corrections that also fail because it doesn't have the correct format readily visible.

Adding a concrete correct example to error messages would help Claude self-correct on the first retry.

## Key Files

- `plugins/core/hooks/validate-ticket.sh` - Validation hook with error messages (lines 75-97 for created_at/author errors)
- `plugins/core/skills/create-ticket/SKILL.md` - Source of truth for correct format (already well-documented)

## Related History

Historical tickets reveal extensive ticket validation and format enforcement infrastructure, including ISO 8601 date validation and effort field constraints.

Past tickets that touched similar areas:

- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Implemented the validation hook
- [20260128002853-extract-create-ticket-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002853-extract-create-ticket-skill.md) - Established ticket format standards

## Implementation Steps

1. **Add example to required field errors** in validate-ticket.sh

   For `created_at` error (around line 82-84):
   ```bash
   echo "Error: created_at must be ISO 8601 format" >&2
   echo "Got: $created_at" >&2
   echo "Example: created_at: 2026-01-31T22:44:08+09:00" >&2
   echo "Run: date -Iseconds" >&2
   exit 2
   ```

   For `author` error (around line 94-96):
   ```bash
   echo "Error: author must be an email address" >&2
   echo "Got: $author" >&2
   echo "Run: git config user.email" >&2
   exit 2
   ```

   For `effort` error (around line 135-137):
   ```bash
   echo "Error: effort must be one of: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h (or empty)" >&2
   echo "Got: $effort" >&2
   echo "Tip: Leave effort empty at creation, fill after implementation" >&2
   exit 2
   ```

2. **Add missing field hint**

   When `created_at` is missing entirely, suggest the field name:
   ```bash
   echo "Error: created_at field is required (not 'date:')" >&2
   echo "Run: date -Iseconds" >&2
   exit 2
   ```

## Considerations

- Error messages should be concise but actionable
- Including "Run: <command>" tells Claude exactly what to do
- The hint about `effort` being empty at creation addresses the t-shirt size mistake
- Adding "(not 'date:')" addresses the common wrong field name
