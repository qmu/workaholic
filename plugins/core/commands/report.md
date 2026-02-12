---
name: report
description: Generate story and create/update a pull request.
---

# Report

**Notice:** When user input contains `/report` - whether "run /report", "do /report", "update /report", or similar - they likely want this command.

Generate story and create or update a pull request for the current branch.

## Instructions

1. **Bump version** following CLAUDE.md Version Management section (patch increment). **Skip if a "Bump version" commit already exists in the current branch** (check with `bash .claude/skills/manage-branch/sh/check-version-bump.sh`; if `already_bumped` is `true`, skip this step).
2. **Invoke story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`)
3. **Display PR URL** from story-writer result (mandatory)
