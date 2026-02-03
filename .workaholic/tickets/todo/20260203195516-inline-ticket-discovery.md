---
title: Inline Discovery in ticket-organizer (Remove Subagents)
type: refactoring
layer: Config
effort: 2h
created_at: 2026-02-03T19:55:16+09:00
author: a@qmu.jp
---

# Inline Discovery in ticket-organizer (Remove Subagents)

## Overview

Fix the `/ticket` command memory leak by removing subagent spawning entirely. Instead of ticket-organizer invoking 3 parallel subagents (history-discoverer, source-discoverer, ticket-moderator), have ticket-organizer perform lightweight inline discovery using Glob and Grep tools directly.

## Motivation

The current architecture violates CLAUDE.md's principle: "Subagent → Subagent (sequential chains cause deep nesting and context explosion)". While the 3 subagents run in parallel, each accumulates its own context window, and the ticket-organizer must synthesize all 3 results. This creates 4 context windows total.

The markdown-based "limits" (under 200 lines) are unenforceable guidelines, not actual code limits.

## Key Files

- `plugins/core/agents/ticket-organizer.md` - Remove Task tool, add inline discovery steps
- `plugins/core/agents/history-discoverer.md` - DELETE
- `plugins/core/agents/source-discoverer.md` - DELETE
- `plugins/core/agents/ticket-moderator.md` - DELETE
- `plugins/core/skills/discover-history/SKILL.md` - DELETE (keep sh/search.sh)
- `plugins/core/skills/discover-source/SKILL.md` - DELETE
- `plugins/core/skills/moderate-ticket/SKILL.md` - DELETE
- `.workaholic/specs/architecture.md` - Update diagrams
- `.workaholic/specs/command-flows.md` - Update /ticket flow

## Implementation

### 1. Update ticket-organizer.md

Remove `Task` from tools list:
```yaml
tools: Read, Write, Edit, Glob, Grep, Bash
```

Replace Step 2 "Parallel Discovery" with inline discovery:

```markdown
### 2. Inline Discovery

Perform lightweight discovery using Glob and Grep tools directly:

**History Discovery**:
1. Run existing search script:
   ```bash
   bash .claude/skills/discover-history/sh/search.sh KEYWORD1 KEYWORD2 KEYWORD3
   ```
2. Parse output (format: `count filepath`)
3. Read top 3 matching tickets (Read with `limit: 50`)
4. Extract title and overview for "Related History" section

**Source Discovery**:
1. Glob for files matching keywords: `**/*keyword*`
2. Grep for function/class names in source files
3. Limit to 10 files maximum
4. Record paths for "Key Files" section (do NOT read full contents)

**Ticket Moderation**:
1. Glob: `.workaholic/tickets/todo/*.md` and `.workaholic/tickets/icebox/*.md`
2. Grep for keywords in found tickets
3. If matches found, Read with `limit: 50` to check overlap
4. Return status: clear, duplicate, or needs_decision
```

### 2. Delete Subagent Files

```bash
rm plugins/core/agents/history-discoverer.md
rm plugins/core/agents/source-discoverer.md
rm plugins/core/agents/ticket-moderator.md
```

### 3. Delete Skill SKILL.md Files

Keep the shell scripts but remove the markdown instructions (no longer needed without subagents):

```bash
rm plugins/core/skills/discover-history/SKILL.md
rm plugins/core/skills/discover-source/SKILL.md
rm plugins/core/skills/moderate-ticket/SKILL.md
```

### 4. Update Documentation

Update architecture.md and command-flows.md (both EN and JA):
- Remove history-discoverer, source-discoverer, ticket-moderator from agents list
- Update /ticket dependency diagram to show direct Glob/Grep usage
- Update component tables

## Considerations

**Tradeoff**: Less "intelligent" discovery (pattern matching vs LLM reasoning). However:
- The current subagent approach was already using simple grep/glob internally
- LLM reasoning adds minimal value for keyword-based file discovery
- Bounded, predictable behavior is more valuable than "smart" discovery that explodes context

**Alternative considered**: Shell scripts returning bounded JSON. This was rejected because:
- Adds complexity (new scripts, JSON parsing)
- Glob/Grep tools already exist and are well-tested
- Inline discovery is simpler and easier to debug

## Verification

1. Run `/ticket add a new feature` - should complete without hanging
2. Verify no Task tool calls in ticket-organizer execution
3. Check ticket file contains Related History and Key Files sections
