---
created_at: 2026-01-31T19:25:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Improve Create-Ticket Skill Frontmatter Clarity

## Overview

The create-ticket skill's frontmatter template and instructions are ambiguous about field requirements, causing frequent validation failures. The skill says to run commands FIRST but shows templates with placeholder values that are easy to copy verbatim. Also, the template doesn't clearly distinguish between "must be present but empty" vs "fill with actual values".

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Main skill with frontmatter template and instructions
- `plugins/core/hooks/validate-ticket.sh` - Validation hook that enforces format

## Related History

Historical tickets show iterative improvements to ticket validation:

- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added PostToolUse validation hook
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Extracted frontmatter update skill

## Implementation Steps

1. **Restructure Step 1 in create-ticket skill** to make dynamic value capture unavoidable:
   - Show a bash script block that captures BOTH values into variables
   - Immediately show how to use those variables in the frontmatter
   - Remove standalone template that shows placeholder values

2. **Update the frontmatter template** to use bash command substitution directly:
   ```yaml
   ---
   created_at: $(date -Iseconds)      # REPLACE with actual output
   author: $(git config user.email)   # REPLACE with actual output
   type: <enhancement | bugfix | refactoring | housekeeping>
   layer: [<UX | Domain | Infrastructure | DB | Config>]
   effort:
   commit_hash:
   category:
   ---
   ```

3. **Add explicit field presence requirement**:
   - Clarify that `effort:`, `commit_hash:`, and `category:` lines MUST be present (even if empty)
   - Add a "Common Mistakes" section listing validation failure causes

4. **Add concrete example** with actual realistic values (not example.com):
   ```yaml
   ---
   created_at: 2026-01-31T19:25:46+09:00
   author: developer@company.com
   type: enhancement
   layer: [UX, Domain]
   effort:
   commit_hash:
   category:
   ---
   ```

## Considerations

- The layer field can be scalar (`Config`) or array (`[Config]`) - both work with current validation, but skill should recommend array format for consistency
- Avoid breaking changes to validation hook - the skill documentation should match what the hook enforces
