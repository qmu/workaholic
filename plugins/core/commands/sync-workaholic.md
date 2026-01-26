---
name: sync-workaholic
description: Sync source code changes to .workaholic/ directory (specs and terminology)
---

# Sync Workaholic

Orchestrate spec-writer and terminology-writer subagents to update `.workaholic/` documentation.

## Instructions

Invoke both subagents in parallel using the Task tool:

1. **spec-writer**: "Update .workaholic/specs/ to reflect the current codebase state. Follow the instructions in your system prompt."

2. **terminology-writer**: "Update .workaholic/terminology/ to maintain consistent term definitions. Follow the instructions in your system prompt."

When both subagents complete, summarize the combined results:

- Specs updated/created/deleted
- Terms added/updated/deprecated
- Any inconsistencies identified
