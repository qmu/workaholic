---
name: report-drive
description: Generate story and create/update a pull request.
---

# Report Drive

**Notice:** When user input contains `/report-drive` - whether "run /report-drive", "do /report-drive", "update /report-drive", or similar - they likely want this command.

Generate story and create or update a pull request for the current branch.

## Instructions

1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/branching/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
2. **Invoke story-writer** (`subagent_type: "drivin:story-writer"`, `model: "opus"`)
3. **Display PR URL** from story-writer result (mandatory)
