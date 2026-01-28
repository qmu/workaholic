---
created_at: 2026-01-28T22:48:41+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Enforce Archive Script Usage in Drive Workflow

## Overview

Claude Code sometimes bypasses the archive script during `/drive` and manually moves tickets to incorrect locations (e.g., `.workaholic/tickets/done/` instead of `.workaholic/tickets/archive/<branch>/`). The instructions say "Always use the script. Never manually move tickets" but this is not forceful enough. Strengthen the language to make it impossible to interpret as optional.

## Key Files

- `plugins/core/skills/drive-workflow/SKILL.md` - Main workflow skill that needs stronger enforcement

## Related History

Past tickets that touched similar areas:

- [20260127100740-ticket-skip-commit-during-drive.md](.workaholic/tickets/archive/feat-20260126-214833/20260127100740-ticket-skip-commit-during-drive.md) - Modified drive workflow commit behavior (same file)
- [20260124002211-include-uncommitted-tickets-in-drive-commit.md](.workaholic/tickets/archive/feat-20260123-191707/20260124002211-include-uncommitted-tickets-in-drive-commit.md) - Modified archive behavior (same layer)

## Implementation Steps

1. In `plugins/core/skills/drive-workflow/SKILL.md` step 5 "Commit and Archive Using Skill":
   - Add explicit prohibition language using DENY/NEVER patterns
   - List what NOT to do (manual `mv`, `git mv`, creating arbitrary directories)
   - State the ONLY valid archive location is `.workaholic/tickets/archive/<branch>/`
   - Emphasize the script handles everything—no manual file operations needed

2. Add a "Prohibited Actions" section near the archive instructions listing:
   - NEVER use `mv` or `git mv` to move tickets
   - NEVER create directories like `done/`, `completed/`, `finished/`
   - NEVER manually update CHANGELOG
   - The ONLY way to archive is via the script

## Considerations

- The language needs to be strong enough that Claude Code cannot rationalize bypassing it
- Use explicit DENY patterns that match how Claude Code interprets prohibitions
- Keep instructions concise—too much text can cause skimming
