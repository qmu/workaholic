---
name: report
description: Context-aware report generation and PR creation for drive and trip workflows.
skills:
  - workaholic:report
---

# Report

**Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command runs the preloaded `workaholic:report` skill. Follow the **Run Workflow** section end-to-end (Workspace Guard, Detect Context, Route by Context with Drive/Trip/Hybrid/Worktree/Unknown subcases). This command (main agent) runs the Write Story orchestration directly and spawns its workers as `general-purpose` subagents — there is no story-writer subagent.

**Policy Lens**: When the `standards` plugin is installed, this command preloads the `workaholic:design`, `workaholic:implementation`, and `workaholic:operation` indexes. **Read them first** (see the skill's `### Policy Lens` step) and use them to judge the branch's design, implementation, behavior, and operation when assessing carry-over concerns, reviewing story sections, and reporting release readiness. If the standards plugin is not connected, skip the lens and proceed.
