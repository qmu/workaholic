# Parallel Discovery in /ticket Command

## Overview

Refactor `/ticket` to run history discovery and source code discovery concurrently, then synthesize both results into the ticket. Currently only history discovery runs; adding source discovery provides richer context about existing code.

## Background

The current `/ticket` command invokes `history-discoverer` sequentially before writing the ticket. The user wants parallel execution:

```
1-A. history-discoverer (haiku) → ticket list, summarized history, analysis
1-B. source-discoverer (haiku)  → file list, summarized code flow, analysis
2.   Generate ticket from both discoveries
```

This follows the established parallel execution pattern used in `/story` command (5 concurrent agents).

## Related History

Historical tickets show evolution toward parallel agent execution. The `/story` command already runs 5 agents concurrently. The nesting policy (CLAUDE.md) allows commands to invoke subagents via Task tool. The `history-discoverer` pattern provides a template for the new `source-discoverer`.

## Key Files

- `plugins/core/commands/ticket.md` - Command to update (invoke both subagents in parallel)
- `plugins/core/agents/history-discoverer.md` - Existing subagent (template for source-discoverer)
- `plugins/core/agents/source-discoverer.md` - New subagent to create
- `plugins/core/skills/discover-source/SKILL.md` - New skill for source exploration guidelines

## Implementation

### 1. Create source-discoverer subagent

Create `plugins/core/agents/source-discoverer.md`:

```markdown
---
name: source-discoverer
description: Find related source files and analyze code flow.
tools: Glob, Grep, Read
skills:
  - discover-source
---

# Source Discoverer

Explore codebase to find files related to a ticket request.

## Input

You will receive:
- Description of the feature/change being planned
- Keywords/file patterns to search for

## Instructions

1. Use Glob to find files matching keywords
2. Use Grep to search for related terms in code
3. Read top 5-10 most relevant files
4. Analyze code flow and dependencies

## Output

Return JSON:

```json
{
  "summary": "1-2 sentence synthesis of codebase context",
  "files": [
    {
      "path": "path/to/file.ts",
      "purpose": "Brief description of what this file does",
      "relevance": "Why this file matters for the ticket"
    }
  ],
  "code_flow": "Brief description of how components interact"
}
```
```

### 2. Create discover-source skill

Create `plugins/core/skills/discover-source/SKILL.md`:

```markdown
---
name: discover-source
description: Guidelines for exploring source code to understand context.
---

# Discover Source

Guidelines for finding and analyzing source code related to a ticket.

## Search Strategy

1. **File patterns**: Search for files matching keywords from the request
2. **Code patterns**: Grep for function names, class names, imports
3. **Dependencies**: Trace imports to understand relationships

## Analysis Focus

- Entry points and main flows
- Data structures and types
- Integration points
- Existing patterns to follow

## Output Format

Provide structured JSON with:
- `summary`: High-level synthesis
- `files`: List of relevant files with purpose and relevance
- `code_flow`: How components interact
```

### 3. Update /ticket command

Modify `plugins/core/commands/ticket.md` step 2 to invoke both subagents in parallel:

**Before:**
```markdown
2. **Discover Related History**

   Use Task tool to invoke history-discoverer subagent with `model: "haiku"`:
   ...
```

**After:**
```markdown
2. **Parallel Discovery**

   Invoke BOTH subagents concurrently using Task tool with `model: "haiku"`:

   **2-A. History Discovery** (history-discoverer):
   - Extract 3-5 keywords from request
   - Receive JSON: summary, tickets list, match reasons

   **2-B. Source Discovery** (source-discoverer):
   - Pass feature description and keywords
   - Receive JSON: summary, files list, code flow

   Example (single message with two Task tool calls):
   - Task 1: "Find related tickets for keywords: ticket.md drive.md parallel"
   - Task 2: "Find source files for: parallel discovery in ticket command"

   Wait for both to complete, then proceed with both results.
```

### 4. Update ticket template usage

Modify step 3 to incorporate both discovery results:
- Use history discovery for "Related History" section
- Use source discovery for "Key Files" section (merge with manual exploration)
- Reference code flow in "Implementation" section

## Verification

- [ ] source-discoverer subagent returns valid JSON
- [ ] Both subagents invoked in parallel (single message, two Task calls)
- [ ] Generated tickets include both historical and source context
- [ ] No regression in ticket quality
- [ ] Follows nesting policy (command → subagent allowed)
