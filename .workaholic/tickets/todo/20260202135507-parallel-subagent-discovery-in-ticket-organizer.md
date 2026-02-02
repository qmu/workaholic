---
created_at: 2026-02-02T13:55:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Parallel Subagent Discovery in ticket-organizer

## Overview

Update the architecture policy to allow subagent-to-subagent invocation, then refactor ticket-organizer to launch history-discoverer and source-discoverer subagents in parallel via the Task tool. This replaces the current skill-based discovery with dedicated subagents that can perform richer analysis.

## Key Files

- `CLAUDE.md` - Architecture policy with nesting rules (lines 32-52)
- `plugins/core/agents/ticket-organizer.md` - Current implementation using skills
- `plugins/core/agents/history-discoverer.md` - Subagent that returns JSON with historical context
- `plugins/core/agents/source-discoverer.md` - Subagent that returns JSON with source context

## Related History

Historical tickets show the nesting policy has been relaxed before (skill-to-skill was added), and parallel discovery was previously implemented at the command level. The original nesting policy explicitly prohibits subagent-to-subagent to prevent "deep nesting and context explosion."

Past tickets that touched similar areas:

- [20260129-parallel-discovery-ticket-command.md](.workaholic/tickets/archive/feat-20260129-023941/20260129-parallel-discovery-ticket-command.md) - Added parallel discovery to /ticket command (same pattern: parallel Task calls)
- [20260131153043-allow-skill-to-skill-nesting.md](.workaholic/tickets/archive/feat-20260131-125844/20260131153043-allow-skill-to-skill-nesting.md) - Previously relaxed nesting rules to allow skill-to-skill (precedent for policy change)
- [20260128004700-document-nesting-policy.md](.workaholic/tickets/archive/feat-20260128-001720/20260128004700-document-nesting-policy.md) - Original nesting policy (explains rationale for subagent-to-subagent prohibition)

## Implementation Steps

### 1. Update Architecture Policy in CLAUDE.md

Modify the nesting rules table to allow subagent-to-subagent invocation with restrictions:

**Before (line 39):**
```
| Subagent | Skill              | Subagent, Command   |
```

**After:**
```
| Subagent | Skill, Subagent    | Command             |
```

Update the Allowed list (after line 45):
```markdown
- Subagent -> Subagent (via Task tool, max depth 1, parallel only recommended)
```

Update the Prohibited list (line 51):
```markdown
- Subagent -> Subagent (nested/sequential) - prevents deep nesting and context explosion
```

Add clarification that subagent-to-subagent is allowed when:
- Invoked in parallel (not sequential chains)
- Max depth of 1 (subagent A can call subagent B, but B cannot call another subagent)
- Results are collected and synthesized by the calling subagent

### 2. Update ticket-organizer.md to Use Task Tool

Replace skill preloads with Task tool invocations for discovery:

**Before (frontmatter):**
```yaml
skills:
  - create-ticket
  - discover-history
  - discover-source
```

**After:**
```yaml
skills:
  - create-ticket
```

### 3. Add Parallel Discovery Step

Update the "## Instructions" section, step 2:

**Before:**
```markdown
### 2. Parallel Discovery

Run all three discovery tasks in parallel:

**2-A. History Discovery**

Follow preloaded **discover-history** skill:
- Search `.workaholic/tickets/archive/` for related tickets
- Extract patterns, decisions, and lessons learned

**2-B. Source Discovery**

Follow preloaded **discover-source** skill:
- Find related source files using keywords
- Analyze code flow and dependencies
```

**After:**
```markdown
### 2. Parallel Discovery

Invoke BOTH subagents concurrently using Task tool:

**2-A. History Discovery** (via Task tool):
```
Task: history-discoverer
Input: "Find related tickets for keywords: <keyword1> <keyword2> ..."
```
- Receive JSON: summary, tickets list, match reasons

**2-B. Source Discovery** (via Task tool):
```
Task: source-discoverer
Input: "Find source files for: <description>"
```
- Receive JSON: summary, files list, code flow

**Implementation:**
Make a single response with two parallel Task tool calls:
- Task 1: history-discoverer with extracted keywords
- Task 2: source-discoverer with feature description

Wait for both to complete, then proceed with both JSON results.
```

### 4. Update Ticket Template Usage

Modify step 5 to reference the JSON outputs:

```markdown
### 5. Write Ticket(s)

Follow preloaded **create-ticket** skill for format and content.

For each ticket:
- Use history discovery JSON for "Related History" section:
  - `summary` field provides the synthesis sentence
  - `tickets` array provides the bullet list with paths and match reasons
- Use source discovery JSON for "Key Files" section:
  - `files` array provides paths and relevance descriptions
- Reference `code_flow` from source discovery in "Implementation" section
```

## Considerations

- **Context explosion**: The original prohibition was to prevent deep nesting. This change allows only parallel invocation at depth 1, which keeps context bounded.
- **Backward compatibility**: Existing commands that invoke ticket-organizer continue to work; they just get richer context.
- **Performance**: Parallel Task calls should complete faster than sequential skill execution since both agents work simultaneously.
- **Error handling**: If either discovery agent fails, ticket-organizer should proceed with partial results rather than failing entirely.
