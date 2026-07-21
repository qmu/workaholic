---
name: carry
description: Hand off in-progress work to a fresh session by writing a resumption ticket a later /drive — or, for a parallel /monitor run, /monitor — continues.
skills:
  - workaholic:carry
---

# Carry

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/carry` - whether "run /carry", "carry this", "hand off", "checkpoint before the window fills", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:carry` skill. Follow its **Run Workflow** section end-to-end (Phase 0 Identify the In-Progress Work, Phase 1 Summarize Remaining Work + Position, Phase 2 Write the Handoff, Phase 3 Report). `$ARGUMENT` is an optional short note to bias the summary; none is needed.

**When to run it:** you run `/carry` yourself when you notice the token window getting short and want to continue in a **fresh** Claude Code session without relying on compaction. There is no automatic trigger — no hook or setting can read the remaining context budget — so `/carry` is an explicit, user-invoked checkpoint (like `/drive night` is an explicit invocation, not a sensed state).

**CRITICAL — capture only:** `/carry` NEVER implements a ticket, edits code toward the task, commits, or archives. It only writes durable resume state — a resumption ticket under `.workaholic/tickets/todo/<user>/`, and/or a trip `plan.md` checkpoint, and/or (for a parallel `/monitor` run) one resumption ticket per in-flight mission inside its own `.worktrees/<slug>/` queue — so a fresh session running `/drive` (or `/monitor`) finds the priority and continues. The build happens later via `/drive` or `/monitor`.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/carry` run (via the marker above). The carried state is documentation for a future agent — keep it objective, verifiable, and machine-actionable (`workaholic:implementation` / `objective-documentation`), and shaped as a recovery checkpoint for the context-exhaustion scenario (`workaholic:implementation` / `operational-planning`).
