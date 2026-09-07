---
name: mission
description: Create a mission (an optional, epic-equivalent grouping — a bounded, information-rich batch of tickets), replan an in-flight one, list existing missions with computed progress, or close one (achieved/abandoned/carried) into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
  - workaholic:branching
  - workaholic:create-ticket
  - workaholic:commit
---

# Mission

Run the preloaded `workaholic:mission` skill's **command flows** (`${CLAUDE_PLUGIN_ROOT}/skills/mission/reference/command-flows.md`) end to end. No word of `$ARGUMENT` is a subcommand: judge it per the flows' *Routing the argument* — a clear reference to one in-flight mission runs the **replan flow**, an ambiguous argument is asked, an argument referencing nothing is a title for the **create flow**, and bare `/mission` opens the **planning session**. Normalize the input once and reuse its discovery and answered decisions across every emitted ticket. The main agent asks only unresolved design questions, with the `[<project label>]` prefix. Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
