---
name: report
description: Generate story and create/update a pull request.
---

# Report

**Notice:** When user input contains `/report` - whether "run /report", "do /report", "update /report", or similar - they likely want this command.

Generate story and create or update a pull request for the current branch.

## Instructions

1. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
2. **Display PR URL** from story-writer result (mandatory)
