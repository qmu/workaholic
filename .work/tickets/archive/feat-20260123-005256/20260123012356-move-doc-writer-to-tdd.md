# Move doc-writer Agent to TDD Plugin

## Overview

The doc-writer agent belongs in the TDD plugin, not core. It's specifically used by the `/drive` command's documentation step (2.3), which is part of the ticket-driven development workflow. Core plugin contains general-purpose agents like `discover-project` and `discover-claude-dir`, while TDD-specific tooling should live in the TDD plugin.

## Key Files

- `plugins/core/agents/doc-writer.md` - Current location (to be moved)
- `plugins/tdd/agents/doc-writer.md` - New location (to be created)
- `plugins/tdd/commands/drive.md` - References doc-writer (may need path update)

## Implementation Steps

1. Create `plugins/tdd/agents/` directory if it doesn't exist

2. Move `plugins/core/agents/doc-writer.md` to `plugins/tdd/agents/doc-writer.md`

3. Delete `plugins/core/agents/doc-writer.md`

4. Update `plugins/tdd/commands/drive.md` if it references a specific path (check if path is mentioned)

5. Update any documentation that references the agent location:
   - `plugins/core/README.md` - Remove doc-writer from agents list if present
   - `plugins/tdd/README.md` - Add doc-writer to agents list

## Considerations

- The agent itself doesn't need content changes, just the location
- Drive command uses `subagent_type: doc-writer` which should work regardless of which plugin defines it
- This aligns with the principle that TDD-specific tooling lives in the TDD plugin
