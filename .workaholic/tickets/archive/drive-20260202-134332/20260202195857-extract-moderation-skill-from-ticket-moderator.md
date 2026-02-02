---
created_at: 2026-02-02T19:58:57+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: dc23546
category: Changed
---

# Extract moderation skill from ticket-moderator subagent

## Overview

The history-discoverer and source-discoverer subagents follow a clean pattern: thin agent files (~40 lines) that preload comprehensive skill files containing the actual logic. The ticket-moderator subagent (51 lines) contains all its moderation logic inline, breaking this pattern. Extract the moderation guidelines into a new `moderate-ticket` skill, making ticket-moderator consistent with its sibling discovery agents.

## Key Files

- `plugins/core/agents/ticket-moderator.md` - Current subagent with inline logic (51 lines)
- `plugins/core/skills/discover-history/SKILL.md` - Pattern to follow (41 lines of skill content)
- `plugins/core/skills/discover-source/SKILL.md` - Pattern to follow (122 lines of skill content)

## Related History

Historical tickets establish a clear pattern: skills contain comprehensive instructions while agents remain thin orchestration layers. The recent parallel discovery work preserved this pattern for history-discoverer and source-discoverer but created ticket-moderator as a new agent without a corresponding skill.

Past tickets that touched similar areas:

- [20260127204529-extract-agent-content-to-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127204529-extract-agent-content-to-skills.md) - Established pattern of extracting agent content to skills (same refactoring pattern)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Created ticket-moderator as new subagent (origin of the inconsistency)
- [20260123020302-doc-writer-agent-to-skill.md](.workaholic/tickets/archive/feat-20260123-005256/20260123020302-doc-writer-agent-to-skill.md) - Earlier agent-to-skill conversion (same pattern)

## Implementation Steps

### 1. Create moderate-ticket skill directory

```bash
mkdir -p plugins/core/skills/moderate-ticket
```

### 2. Create skill file with extracted logic

Create `plugins/core/skills/moderate-ticket/SKILL.md`:

```yaml
---
name: moderate-ticket
description: Guidelines for analyzing existing tickets to detect duplicates, merge candidates, and split opportunities.
user-invocable: false
---
```

Extract and expand the following content from ticket-moderator.md:
- Duplicate detection criteria (80%+ overlap threshold)
- Merge candidate criteria (40-80% overlap)
- Split candidate criteria (too broad scope)
- Related ticket identification
- Overlap percentage evaluation methodology
- Actionable recommendation format
- Output JSON schema with examples

### 3. Thin down ticket-moderator.md

Update the agent file to follow the pattern of history-discoverer and source-discoverer:

**Before (~51 lines):**
- Inline instructions for duplicate/merge/split analysis
- Evaluation criteria embedded in agent

**After (~35 lines):**
```yaml
---
name: ticket-moderator
description: Analyze existing tickets for duplicates, merge candidates, and split opportunities.
tools: Glob, Read, Grep
model: haiku
skills:
  - moderate-ticket
---

# Ticket Moderator

Analyze existing tickets to determine if a proposed ticket should proceed, merge with existing, or trigger a split.

## Input

You will receive:
- Keywords describing the proposed ticket
- Brief description of what the ticket will implement

## Instructions

1. Follow preloaded **moderate-ticket** skill for evaluation guidelines
2. Search `.workaholic/tickets/todo/*.md` and `.workaholic/tickets/icebox/*.md`
3. Apply overlap analysis criteria from skill
4. Return structured JSON recommendation

## Output

Return JSON with status, matches, and recommendation (see skill for schema).
```

### 4. Verify skill loading

Ensure the skill is properly loaded by the agent by checking:
- Frontmatter `skills:` field references `moderate-ticket`
- Skill file exists at expected path
- Skill content is comprehensive enough for standalone use

## Considerations

- **Skill content expansion**: The current agent has minimal moderation logic. The skill should expand on overlap percentage calculation, provide examples of duplicate vs. merge vs. related categorizations, and include edge cases.
- **No shell script needed**: Unlike discover-history which has a search script, moderation is pure analysis using Read/Glob/Grep tools.
- **Consistency with siblings**: After this change, all three parallel discovery agents (history-discoverer, source-discoverer, ticket-moderator) will follow the same pattern: thin agent + comprehensive skill.

## Final Report

Extracted moderation logic from ticket-moderator agent into a new moderate-ticket skill:

- Created `plugins/core/skills/moderate-ticket/SKILL.md` (122 lines) with comprehensive guidelines for overlap analysis, category definitions (duplicate/merge/split/related), overlap percentage calculation methodology, and output schema with examples
- Thinned `plugins/core/agents/ticket-moderator.md` from 51 to 47 lines by adding `skills: [moderate-ticket]` and delegating detailed evaluation criteria to the skill
- Achieved consistency with sibling agents: all three (history-discoverer, source-discoverer, ticket-moderator) now follow the thin-agent + comprehensive-skill pattern
