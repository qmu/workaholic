---
created_at: 2026-02-02T12:58:14+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: 6b8cda1
category: Changed
---

# Refactor /ticket Command to Thin Alias for ticket-writer Subagent

## Overview

Refactor the `/ticket` command to follow the thin command pattern. The command orchestrates parallel discovery (invoking history-discoverer and source-discoverer), then passes results to a new `ticket-writer` subagent that writes tickets based on the discovery context.

**Architecture Constraint**: Subagents cannot invoke other subagents. Therefore:
- **Command** invokes history-discoverer and source-discoverer in parallel
- **Command** passes discovery results to ticket-writer subagent
- **ticket-writer** writes tickets using discovery context and create-ticket skill

## Key Files

- `plugins/core/commands/ticket.md` - Command to refactor (keeps discovery orchestration, delegates writing)
- `plugins/core/commands/drive.md` - Reference pattern for thin command invoking subagents
- `plugins/core/agents/driver.md` - Reference pattern for subagent structure
- `plugins/core/agents/history-discoverer.md` - Discovery subagent (invoked by command, not ticket-writer)
- `plugins/core/agents/source-discoverer.md` - Discovery subagent (invoked by command, not ticket-writer)
- `plugins/core/skills/create-ticket/SKILL.md` - Skill to be preloaded by ticket-writer

## Related History

- `20260129020653-add-command-flow-spec.md` - Established thin command/subagent orchestration pattern
- `20260129015817-add-discover-history-subagent.md` - Created history-discoverer subagent
- `20260131162854-extract-update-ticket-frontmatter-skill.md` - Similar skill extraction pattern

## Implementation

1. **Create ticket-writer subagent** (`plugins/core/agents/ticket-writer.md`)
   - Frontmatter: tools (Read, Write, Edit, Glob, Grep), skills (create-ticket)
   - Input: request description, target directory, history_context JSON, source_context JSON
   - Follow create-ticket skill for exploration and ticket writing
   - Output JSON with ticket paths, titles, queue status
   - **CRITICAL**: Never commit - return summary for parent command

2. **Refactor ticket.md command** (~50-60 lines)
   - Step 0: Branch check (keep)
   - Step 1: Request validation (keep)
   - Step 2: Parallel discovery - invoke history-discoverer and source-discoverer (keep in command)
   - Step 3: Invoke ticket-writer with discovery results
   - Step 4: Commit handling (keep)
   - Step 5: Presentation (keep)

3. **Remove from command**:
   - Complexity evaluation (move to ticket-writer)
   - Ticket writing logic (move to ticket-writer)
   - Clarifying questions (move to ticket-writer - it can ask via output, command relays)

## Considerations

- Per architecture policy: "Subagent → Subagent (prevents deep nesting and context explosion)" is prohibited
- The command must orchestrate all subagent invocations; ticket-writer only receives results
- The `create-branch` skill can be removed from ticket-writer (command handles branching)
- Clarifying questions: ticket-writer returns JSON with `needs_clarification` field and questions; command presents to user

## Final Report

Implementation diverged from original plan based on user feedback:

1. **Renamed to ticket-organizer** (not ticket-writer) - better reflects comprehensive role
2. **Merged all discovery into ticket-organizer** - the subagent now handles history discovery, source discovery, and duplicate checking internally using preloaded skills (discover-history, discover-source)
3. **Command became thinner** (~50 lines) - only handles branch check, subagent invocation, commit, and presentation
4. **Removed ticket-discoverer** - duplicate/merge/split checking merged into ticket-organizer

Files changed:
- Created: `plugins/core/agents/ticket-organizer.md`
- Modified: `plugins/core/commands/ticket.md` (thin alias)
- Modified: `.workaholic/specs/architecture.md` and `architecture_ja.md`
- Deleted: `plugins/core/agents/ticket-writer.md` (never committed, replaced by ticket-organizer)
