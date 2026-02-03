---
created_at: 2026-02-03T17:40:22+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Fix Effort Field Format Guidance

## Overview

After user approval in the `/drive` workflow, Claude Code attempts to update the ticket effort field but uses t-shirt size values like "S" instead of the required hour-based format. The validation hook rejects these values, causing the workflow to fail. The `write-final-report` skill needs clearer guidance to prevent this misunderstanding.

## Key Files

- `plugins/core/skills/write-final-report/SKILL.md` - Primary file to fix; must emphasize valid effort format
- `plugins/core/skills/update-ticket-frontmatter/SKILL.md` - Already has correct documentation, skill preloaded by write-final-report
- `plugins/core/hooks/validate-ticket.sh` - Validation logic that rejects invalid effort values (lines 155-164)

## Related History

The effort field format was established when the update-ticket-frontmatter skill was extracted, and the validation hook enforces strict hour-based values.

Past tickets that touched similar areas:

- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Created the update-ticket-frontmatter skill with effort field handling
- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added ticket validation hook that enforces field formats

## Implementation Steps

1. Update `plugins/core/skills/write-final-report/SKILL.md` to add a prominent warning box before the valid values list:
   - Add explicit "INVALID" examples: `XS`, `S`, `M`, `L`, `XL`, `10m`, `30m`
   - Make the valid values list more prominent with a table format
   - Add estimation guidelines to help map complexity to hour values

2. Add a "Common Mistake" section that explicitly states:
   - DO NOT use t-shirt sizes (XS, S, M, L, XL)
   - DO NOT use minute-based values (10m, 30m)
   - ALWAYS use the exact valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

3. Add a mapping guide to help estimate effort:
   - `0.1h` - Trivial changes (typo fix, config tweak)
   - `0.25h` - Simple changes (add field, update text)
   - `0.5h` - Small feature or fix (new function, bug fix)
   - `1h` - Medium feature (new component, refactor)
   - `2h` - Large feature (new workflow, significant refactor)
   - `4h` - Very large feature (new system, major rewrite)

## Considerations

- The skill already preloads `update-ticket-frontmatter` which has correct documentation, but Claude Code may not always consult it when writing effort values
- Making the guidance more prominent in `write-final-report` itself should reduce errors
- The validation hook provides the safety net, but better guidance prevents workflow interruptions
