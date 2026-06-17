---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - workaholic:drive
---

# Drive

**Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command runs the preloaded `workaholic:drive` skill. Follow the **Command Workflow** section end to end (Pre-check, Phase 0 Worktree Guard, Phase 1 Navigate Tickets, Phase 2 Implement Tickets, Phase 3 Re-check and Continue, Phase 4 Completion, Critical Rules).

This command (main agent) owns all navigation user-interaction: it spawns the ticket prioritizer as a `general-purpose` subagent and issues every `AskUserQuestion` (order confirmation, icebox/stop, abandonment) itself — there is no `drive-navigator` subagent.

**Night mode**: when the invocation contains "night" (e.g. "go night /drive"), follow the skill's **Night Mode** section — the `/drive night` invocation authorizes the whole prioritized queue, so run it autonomously with **no per-ticket checkbox**. Ask **one** question only when the queued tickets span clearly distinct topic groups (whether to include Group B while working on Group A); otherwise ask nothing. Then run the batch autonomously (skip the per-ticket approval gate, auto-commit + archive each, skip-and-record on failure), and print a whole-night report for morning review.
