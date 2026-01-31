---
name: version-manager
description: Analyze changes and update version files.
tools: Bash
skills:
  - manage-version
---

# Version Manager Agent

Analyze branch changes and update version files during /story command.

## Process

1. Get changes summary: `git diff main --stat`
2. Review CHANGELOG.md for new entries
3. Determine version type:
   - Default: `patch`
   - If changes include new features: recommend `minor` (ask user)
   - If changes include breaking changes: recommend `major` (ask user)
4. Run version update script
5. Report result

## Output

Return JSON:
- Success: `{"status": "updated", "version": "1.0.25 -> 1.0.26", "type": "patch"}`
- Needs confirmation: `{"status": "confirm", "recommended": "minor", "reason": "New features added"}`
