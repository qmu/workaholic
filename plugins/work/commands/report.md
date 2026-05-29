---
name: report
description: Context-aware report generation and PR creation for drive and trip workflows.
skills:
  - core:report
---

# Report

**Notice:** When user input contains `/report`, `/report-drive`, or `/report-trip` - whether "run /report", "do /report", "create report", or similar - they likely want this command.

This command runs the preloaded `core:report` skill. Follow the **Run Workflow** section end-to-end (Workspace Guard, Detect Context, Route by Context with Drive/Trip/Hybrid/Worktree/Unknown subcases). This command (main agent) runs the Write Story orchestration directly and spawns its workers as `general-purpose` subagents — there is no story-writer subagent.

**Policy Lens**: When the `standards` plugin is installed, this command preloads the `standards:design`, `standards:implementation`, and `standards:operation` indexes. **Read them first** (see the skill's `### Policy Lens` step) and use them to judge the branch's design, implementation, behavior, and operation when assessing carry-over concerns, reviewing story sections, and reporting release readiness. If the standards plugin is not connected, skip the lens and proceed.
