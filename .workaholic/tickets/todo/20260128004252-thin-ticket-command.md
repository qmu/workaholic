---
created_at: 2026-01-28T00:42:52+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Thin ticket command by moving content to create-ticket skill

## Overview

The `ticket.md` command contains detailed instructions that duplicate content already in the `create-ticket` skill. Since the skill is preloaded, the command should be minimal - just handling the workflow aspects (when to commit, how to present results). All ticket creation knowledge belongs in the skill.

Current state:
- `ticket.md` has detailed "Related History" instructions that are already in `create-ticket` skill
- The skill already covers: filename convention, file structure, frontmatter fields, exploration, related history, writing guidelines

The command should only cover:
- Parse `$ARGUMENT` (icebox detection)
- Reference the skill for all ticket creation
- Handle commit decision (skip during `/drive`)
- Handle presentation (count tickets, tell user to run `/drive`)

## Key Files

- `plugins/core/commands/ticket.md` - Command to thin down
- `plugins/core/skills/create-ticket/SKILL.md` - Skill that already has the content

## Implementation Steps

1. **Simplify ticket.md command**:
   - Keep only workflow steps (argument parsing, commit decision, presentation)
   - Remove any duplicate content already in create-ticket skill
   - Reference skill for all ticket creation details
   - Target: ~30 lines

2. **Verify create-ticket skill is complete**:
   - Ensure all necessary instructions are in the skill
   - Add any missing content from the command before removing it

## Considerations

- The skill is preloaded via `skills: [create-ticket]` in frontmatter
- Preloaded skills inject their full content into the command context
- Duplication wastes context tokens and can cause inconsistency
