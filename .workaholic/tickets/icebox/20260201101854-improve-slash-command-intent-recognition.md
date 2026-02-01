---
created_at: 2026-02-01T10:19:24+09:00
author: a@qmu.jp
type: bugfix
layer: [UX]
effort:
commit_hash:
category:
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

Add a general.md rule that reinforces slash command recognition patterns. This rule will be always-on and guide Claude Code to recognize natural language variations.

## Key Files

- `plugins/core/rules/general.md` - Add slash command intent recognition rule

## Related History

- `20260129003905-rename-report-to-story.md` - Renamed /report to /story, showing command naming matters
- `20260131153043-allow-skill-to-skill-nesting.md` - Skill architecture and invocation patterns

## Implementation

1. Add a new section to `plugins/core/rules/general.md`:
   ```markdown
   ## Slash Command Recognition

   When user input contains a slash command reference (e.g., `/story`, `/drive`, `/ticket`):
   - Invoke the command via the Skill tool immediately
   - Do NOT ask clarifying questions about which command or what to do
   - Natural language variations all mean "run this command":
     - "update /story" → invoke /story
     - "do /story" → invoke /story
     - "run /story" → invoke /story
     - "execute /story command" → invoke /story
     - "can you /story" → invoke /story
   - The slash prefix is the definitive signal - any surrounding words are just natural language
   ```

## Acceptance Criteria

- [ ] User says "update /story" → Claude invokes /story command
- [ ] User says "do /drive" → Claude invokes /drive command
- [ ] User says "run /ticket foo" → Claude invokes /ticket with arg "foo"
- [ ] No clarifying questions asked when slash command is clearly referenced

## Notes

This is a UX fix to reduce friction when users naturally phrase requests involving slash commands. The slash prefix is already a clear signal of intent - no additional confirmation needed.
