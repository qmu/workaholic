---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - workaholic:trip-protocol
---

# Trip

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs either in an isolated git worktree or on a trip branch in the main working tree.

**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.

Follow the preloaded **workaholic:trip-protocol** skill `## Trip Command Procedure` for the full five-step orchestration: Pre-check, Create or Resume Trip, Initialize Trip Artifacts, Validate Dev Environment, Launch Agent Teams (with verbatim team-lead instruction), Present Results.

**Night mode**: when the invocation contains "night" (e.g. "go night /trip", "/trip night build X"), follow the skill's **Night Mode** section — the `/trip night` invocation authorizes a fully unattended run, so the trip asks the developer **nothing**. Strip the `night` token (the remainder is the trip instruction), auto-resolve setup to a new isolated worktree (no `AskUserQuestion`), append the night directive to the team-lead instruction so the team judges everything itself (resolving disagreements through trip-protocol's own review/moderation/convergence machinery and recording assumptions rather than asking), park gracefully on any blocker, and emit a morning-review report instead of the interactive presentation.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/trip` run (via the marker above), consistent with the other workflow commands. Load and apply `workaholic:planning`, `workaholic:design`, `workaholic:implementation`, and `workaholic:operation` so the trip's planning, design, build, and ship-handoff phases are judged against the project's policies — Planner against `planning`/`design`, Architect bridging `design`↔`implementation`, Constructor against `implementation`/`operation`. The `workaholic:trip-protocol` skill already soft-preloads these; the marker makes the lens always-on for `/trip`.
