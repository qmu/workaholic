---
created_at: 2026-01-28T00:28:53+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: S
commit_hash: 51f7384
category: Added
---

# Extract create-ticket skill from ticket command and merge define-ticket-format

## Overview

The `/ticket` command (86 lines) contains detailed instructions for ticket creation that should be extracted into a dedicated `create-ticket` skill, following the established pattern where commands become lightweight orchestrators referencing skills. Additionally, the existing `define-ticket-format` skill should be merged into the new `create-ticket` skill since ticket format is integral to ticket creation.

This consolidation simplifies the skill hierarchy: instead of `ticket.md` → `define-ticket-format` (preloaded), we get `ticket.md` → `create-ticket` (preloaded, contains format).

## Key Files

- `plugins/core/commands/ticket.md` - Reduce to orchestrator (~30 lines)
- `plugins/core/skills/define-ticket-format/SKILL.md` - Delete after merging
- `plugins/core/skills/create-ticket/SKILL.md` - New skill to create

## Related History

Previous refactorings followed this same pattern of extracting command content into skills.

Past tickets that touched similar areas:

- `20260127100902-extract-drive-ticket-skills.md` - Created ticket-format and drive-workflow skills (same pattern)
- `20260127204529-extract-agent-content-to-skills.md` - Extracted agent content to skills (same pattern)
- `20260127020640-extract-changelog-skill.md` - Extracted changelog skill from agent (same layer: Config)

## Implementation Steps

### 1. Create `create-ticket` skill

Create `plugins/core/skills/create-ticket/SKILL.md` with:

```yaml
---
name: create-ticket
description: Create implementation tickets with proper format and conventions.
user-invocable: false
---
```

Content to include (merged from both sources):

**From `define-ticket-format` (all content):**
- Filename convention (YYYYMMDDHHmmss-<short-description>.md)
- File structure template
- Frontmatter fields documentation (required at creation, filled after implementation)

**From `ticket.md` (instruction details):**
- How to explore the codebase (step 2)
- How to find related history (step 3)
- Related History section format example
- How to synthesize history summary
- Notes section (why/what focus, actionable steps, reference patterns)

### 2. Update ticket.md

Reduce to orchestrator:

```yaml
---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - create-ticket
---
```

Keep only high-level orchestration:
1. Understand the Request (parse $ARGUMENT, icebox detection)
2. Explore and Write Ticket → reference create-ticket skill
3. Ask Clarifying Questions (brief mention)
4. Commit the Ticket (with drive-context skip note)
5. Present the Ticket (count queued, prompt for /drive)

Target: ~30 lines

### 3. Delete define-ticket-format skill

Remove `plugins/core/skills/define-ticket-format/` directory since its content is now in `create-ticket`.

## Considerations

- The `create-ticket` skill name follows verb-noun convention like `write-story`, `write-spec`
- The new skill is not user-invocable (preloaded by ticket command only)
- Keep the skill self-contained - it should have all info needed to create a ticket
- Maintain the same behavior: filename format, frontmatter fields, related history

## Final Report

Created the create-ticket skill combining content from both define-ticket-format and ticket.md. The new skill includes filename convention, file structure, frontmatter fields, codebase exploration instructions, related history finding, and writing guidelines. Reduced ticket.md from 86 lines to 47 lines by extracting detailed instructions to the skill while keeping orchestration logic. Deleted the define-ticket-format skill directory.
