---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - core:drive
---

# Drive

**Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

This command runs the preloaded `core:drive` skill. Follow the **Command Workflow** section end to end (Pre-check, Phase 0 Worktree Guard, Phase 1 Navigate Tickets, Phase 2 Implement Tickets, Phase 3 Re-check and Continue, Phase 4 Completion, Critical Rules).

This command (main agent) owns all navigation user-interaction: it spawns the ticket prioritizer as a `general-purpose` subagent and issues every `AskUserQuestion` (order confirmation, icebox/stop, abandonment) itself — there is no `drive-navigator` subagent.
