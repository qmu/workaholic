---
created_at: 2026-01-31T19:23:43+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.1h
commit_hash: e6f8e98
category:
---

# Fix write-story Skill Performance-Analyst Invocation

## Overview

Remove outdated instruction in write-story skill that tells agents to invoke performance-analyst via Task tool. Since performance-analyst was moved to Phase 1 parallel execution, the output is now provided by the `/story` command orchestrator, not invoked by story-writer. Update documentation to match release-readiness pattern.

## Key Files

- `plugins/core/skills/write-story/SKILL.md` - Lines 157-165 contain outdated invocation instructions

## Implementation

1. Replace lines 157-165 in `write-story/SKILL.md`:

   **Before:**
   ```markdown
   **Invoking performance-analyst:**

   Use the Task tool with `subagent_type: "core:performance-analyst"` and provide:

   - Archived tickets for this branch
   - Git log (main..HEAD)
   - Performance metrics from frontmatter

   The subagent returns the table and analysis in the format shown above. Include its complete output in section 9.2.
   ```

   **After:**
   ```markdown
   **Performance-analyst input:**

   The performance-analyst markdown is provided by the orchestrator (`/story` command) which invokes performance-analyst as a parallel agent. Include the complete output in section 9.2.
   ```

## Related History

- `20260131182901-move-performance-analyst-to-phase1.md` - Moved performance-analyst to Phase 1 parallel execution

## Out of Scope

- Changing architecture policy documentation
- Modifying story-writer agent or /story command
