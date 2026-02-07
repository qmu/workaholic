---
name: story
description: Partial-scan documentation, generate story, and create/update PR.
---

# Story

**Notice:** When user input contains `/story` - whether "run /story", "do /story", "update /story", or similar - they likely want this command.

Run a partial documentation scan (only agents relevant to branch changes), then generate a story and create or update a pull request.

## Instructions

1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`) with prompt: `"Scan documentation. mode: partial"`
2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
3. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
4. **Display PR URL** from story-writer result (mandatory)
