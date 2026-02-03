---
created_at: 2026-02-03T17:23:54+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Add unified diff patches to ticket format

## Overview

Enhance the ticket creation workflow to include a "## Patches" section containing unified diff format patches that show exact file changes. When `/drive` processes a ticket, it can start by applying these patches directly to the codebase rather than interpreting prose descriptions. This reduces ambiguity, ensures precision, and accelerates implementation by giving Claude a concrete starting point.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Add Patches section to the ticket format template
- `plugins/core/agents/ticket-organizer.md` - Update to invoke patch generation after source discovery
- `plugins/core/skills/drive-workflow/SKILL.md` - Add patch application step before implementation
- `plugins/core/agents/source-discoverer.md` - Enhance to return code snippets for patch generation
- `plugins/core/skills/discover-source/SKILL.md` - Add guidelines for capturing relevant code snippets

## Related History

Ticket creation and drive implementation have evolved together. Past enhancements added source discovery for better context, related history for pattern awareness, and structured frontmatter for metadata. This enhancement continues that trajectory by making tickets more precise and actionable.

Past tickets that touched similar areas:

- [20260127101903-add-related-history-to-tickets.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101903-add-related-history-to-tickets.md) - Added Related History section to tickets (same component: create-ticket)
- [20260127100902-extract-drive-ticket-skills.md](.workaholic/tickets/archive/feat-20260126-214833/20260127100902-extract-drive-ticket-skills.md) - Extracted drive and ticket skills (same components: drive-workflow, create-ticket)

## Implementation Steps

1. **Update `create-ticket/SKILL.md`** to add a new "## Patches" section after Implementation Steps:

   ```markdown
   ## Patches

   Unified diff patches for key changes. Apply with `git apply --check` to validate, then `git apply` to apply.

   ### `path/to/file.ext`

   ```diff
   --- a/path/to/file.ext
   +++ b/path/to/file.ext
   @@ -10,6 +10,8 @@ existing context line
    unchanged line
   -removed line
   +added line
    more context
   ```
   ```

2. **Update `discover-source/SKILL.md`** to capture code snippets:
   - In Phase 1 (Direct Matches), read key sections of matching files
   - Store relevant code blocks that will likely need modification
   - Add `snippets` field to output JSON:
     ```json
     {
       "files": [...],
       "snippets": [
         {
           "path": "path/to/file.ts",
           "start_line": 10,
           "end_line": 25,
           "content": "actual code content"
         }
       ]
     }
     ```

3. **Update `source-discoverer.md`** to return snippets in output JSON

4. **Update `ticket-organizer.md`** step 5 (Write Ticket):
   - After getting source discovery JSON, use `snippets` to generate diff patches
   - Generate unified diff format based on implementation steps and snippets
   - Write patches to the Patches section of the ticket
   - Mark patches as "proposed" (not yet validated)

5. **Update `drive-workflow/SKILL.md`** step 2 (Implement):
   - Add step 2.0: "Check for Patches section"
   - If Patches exist:
     - Validate with `git apply --check <patch>`
     - Apply with `git apply <patch>` if valid
     - Report which patches applied successfully
     - Fall back to manual implementation for failed patches
   - If no Patches section, proceed with existing workflow

6. **Add patch generation guidelines** to create-ticket skill:
   - Patches should be small and focused (max 50 lines per file)
   - Include 3 lines of context for each hunk
   - Use relative paths from repository root
   - Group related changes in the same patch
   - Mark speculative patches with a warning comment

## Considerations

- **Patch accuracy**: Patches generated during ticket creation may become stale if the codebase changes before `/drive` runs. The workflow should validate patches before applying and gracefully fall back to manual implementation if patches fail.

- **Complexity threshold**: Not all tickets need patches. Simple changes (rename, add new file) may not benefit from patches. Consider making patches optional based on complexity.

- **LLM context usage**: Large patches consume context window. Keep patches focused on key changes rather than entire files.

- **Diff format compatibility**: Use standard unified diff format for compatibility with `git apply`. Avoid non-standard extensions.

- **Separation of concerns**: Patch generation could be extracted to a separate skill (e.g., `generate-patches`) if the logic becomes complex. For now, inline in ticket-organizer is acceptable.
