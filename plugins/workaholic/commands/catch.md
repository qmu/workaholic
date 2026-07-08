---
name: catch
description: By-developer catch-up report over a recent window (commits, tickets, stories, mission progress), then follow-up Q&A.
skills:
  - workaholic:catch
---

# Catch

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/catch` - whether "run /catch", "catch me up", "what has everyone been working on", "summarize the last two weeks", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:catch` skill. Follow the **Run Workflow** section end-to-end (Phase 0 Gather the Window and Roster, Phase 1 Collect Per Developer, Phase 2 Synthesize the Report, Phase 3 Stand Ready for Questions). The command spawns the per-developer collectors as `general-purpose` subagents (`model: "haiku"`); all synthesis and follow-up Q&A happen at the main-agent level. `$ARGUMENT` is an optional window (e.g. `/catch 30 days`); default is the last two weeks.

`/catch` is **read-only** — it reads tickets, stories, docs, commit messages, and missions, and writes nothing. It never creates, moves, or archives tickets, and never mutates a mission (no changelog append, no acceptance tick). The report includes a top-level **Missions** section (each active mission's derived progress plus its merged and unmerged in-flight work) and a per-developer mission-attribution line.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/catch` run (via the marker above). Use `workaholic:planning`/`design`/`implementation`/`operation` only to frame how each developer's direction maps to the pillars — keep the report factual and verifiable (`workaholic:implementation` / `objective-documentation`), never a grade.
