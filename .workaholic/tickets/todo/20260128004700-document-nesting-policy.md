---
created_at: 2026-01-28T00:47:00+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Document architectural nesting policy in CLAUDE.md

## Overview

Add an "Architecture Policy" section to the root CLAUDE.md documenting the allowed nesting relationships between commands, skills, and subagents. This policy clarifies which component types can invoke which other types, and establishes the principle of thin commands/agents with comprehensive skills.

## Key Files

- `CLAUDE.md` - Add new Architecture Policy section

## Related History

CLAUDE.md has been updated multiple times for project structure documentation but never included explicit nesting rules for component types.

Past tickets that touched similar areas:

- `20260127014257-rename-pull-request-to-report.md` - Updated CLAUDE.md commands table (same file)
- `20260127013941-remove-commit-command.md` - Updated CLAUDE.md commands table (same file)

## Implementation Steps

1. Add a new "## Architecture Policy" section after "## Project Structure" in CLAUDE.md

2. Document the nesting rules:

   ```markdown
   ## Architecture Policy

   ### Component Nesting Rules

   | Caller   | Can invoke         | Cannot invoke       |
   | -------- | ------------------ | ------------------- |
   | Command  | Skill, Subagent    | —                   |
   | Subagent | Skill              | Subagent, Command   |
   | Skill    | —                  | Subagent, Command   |

   **Allowed**:
   - Command → Skill (preload via `skills:` frontmatter)
   - Command → Subagent (via Task tool)
   - Subagent → Skill (preload via `skills:` frontmatter)

   **Prohibited**:
   - Skill → Subagent (skills are passive knowledge, not orchestrators)
   - Skill → Command (skills cannot invoke user-facing commands)
   - Subagent → Subagent (prevents deep nesting and context explosion)
   - Subagent → Command (subagents are invoked by commands, not the reverse)

   ### Design Principle

   **Thin commands and subagents, comprehensive skills.**

   - **Commands**: Orchestration only (~50-100 lines). Define workflow steps, invoke subagents, handle user interaction.
   - **Subagents**: Orchestration only (~20-40 lines). Define input/output, preload skills, minimal procedural logic.
   - **Skills**: Comprehensive knowledge (~50-150 lines). Contain templates, guidelines, rules, and bash scripts.

   Skills are the knowledge layer. Commands and subagents are the orchestration layer.
   ```

## Considerations

- Currently `write-story/SKILL.md` line 157 and `story-writer.md` line 34 invoke performance-analyst subagent, violating this policy. A follow-up ticket should fix this by moving the invocation logic to the orchestrator level.
- The policy is aspirational - some existing code may need refactoring to comply
