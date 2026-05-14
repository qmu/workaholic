---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - core:trip-protocol
---

# Trip

**Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs either in an isolated git worktree or on a trip branch in the main working tree.

**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.

Follow the preloaded **core:trip-protocol** skill `## Trip Command Procedure` for the full five-step orchestration: Pre-check, Create or Resume Trip, Initialize Trip Artifacts, Validate Dev Environment, Launch Agent Teams (with verbatim team-lead instruction), Present Results.
