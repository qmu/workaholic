---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - workaholic:trip-protocol
---

# Trip

**Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`core:`, `work:`, `standards:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin` and `trippin` are obsolete names long since merged into `work`. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs either in an isolated git worktree or on a trip branch in the main working tree.

**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.

Follow the preloaded **workaholic:trip-protocol** skill `## Trip Command Procedure` for the full five-step orchestration: Pre-check, Create or Resume Trip, Initialize Trip Artifacts, Validate Dev Environment, Launch Agent Teams (with verbatim team-lead instruction), Present Results.
