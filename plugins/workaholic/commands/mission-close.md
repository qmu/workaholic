---
name: mission-close
description: End a mission - achieved, abandoned, or carried - and move it into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
  - workaholic:branching
  - workaholic:commit
---

# Mission Close

Run the preloaded `workaholic:mission` skill's **close flow** (`${CLAUDE_PLUGIN_ROOT}/skills/mission/reference/command-flows.md`) end to end. `$ARGUMENT` is the slug of the mission to end, optionally with the outcome — it selects no mode. State the Mission Position Report before asking anything; the three-way outcome (achieved | abandoned | carried) is asked by this command (main agent, `[<project label>]`-prefixed — a subagent cannot ask) only when the argument does not state it; `close.sh` stays the only sanctioned writer of an end state, run inside a publish tree. Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
