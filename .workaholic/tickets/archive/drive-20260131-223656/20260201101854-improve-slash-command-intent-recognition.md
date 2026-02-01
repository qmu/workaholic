---
created_at: 2026-02-01T10:19:24+09:00
author: a@qmu.jp
type: bugfix
layer: [UX]
effort: 0.1h
commit_hash: 8dd3d87
category: Changed
---

# Improve Slash Command Intent Recognition

## Overview

When users say "update /story", "do /story", "run /story", or similar variations, Claude Code asks clarifying questions instead of invoking the `/story` command directly. This frustrates users who expect natural language recognition of slash command references.

## Current Behavior

User: "update /story"
Claude Code: "What story would you want me to update?"

User: "do /story command"
Claude Code: [asks clarifying questions instead of invoking]

## Expected Behavior

User: "update /story"
Claude Code: [invokes /story command via Skill tool]

User: "run the /drive command"
Claude Code: [invokes /drive command via Skill tool]

## Root Cause Analysis

Claude Code's built-in system prompt includes guidance for the Skill tool:
> When users reference a "slash command" or "/<something>", they are referring to a skill. Use this tool to invoke it.

However, this guidance only covers exact slash command mentions, not natural language variations like:
- "update /story" - verb + slash command
- "do /story" - imperative + slash command
- "run /story" - action verb + slash command
- "execute /story command" - longer phrase with slash command

The current guidance doesn't emphasize that ANY mention of a slash command in user input should trigger the Skill tool invocation, regardless of surrounding words.

## Solution

Add a strong, concise invocation note to each command file. Commands should self-declare when to invoke them, rather than relying on a central rule.

## Key Files

- `plugins/core/commands/story.md` - Add invocation note
- `plugins/core/commands/drive.md` - Add invocation note
- `plugins/core/commands/ticket.md` - Add invocation note

## Related History

- `20260129003905-rename-report-to-story.md` - Renamed /report to /story, showing command naming matters
- `20260131153043-allow-skill-to-skill-nesting.md` - Skill architecture and invocation patterns

## Implementation

Add an invocation note after the main header in each command file:

```markdown
> **Invoke immediately** when user mentions `/<command>` in any form.
```

This keeps invocation guidance co-located with the command itself.

## Acceptance Criteria

- [ ] User says "update /story" → Claude invokes /story command
- [ ] User says "do /drive" → Claude invokes /drive command
- [ ] User says "run /ticket foo" → Claude invokes /ticket with arg "foo"
- [ ] No clarifying questions asked when slash command is clearly referenced

## Notes

This is a UX fix to reduce friction when users naturally phrase requests involving slash commands. The slash prefix is already a clear signal of intent - no additional confirmation needed.
