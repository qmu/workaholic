---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - workaholic:create-ticket
  - workaholic:branching
  - workaholic:gather
---

# Ticket

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

Run the preloaded `workaholic:create-ticket` skill's **Workflow** end-to-end (Pre-check through Publish and Present), with `$ARGUMENT` as the request description. Never implement code — the ticket is implemented later by `/drive`. Bare `/ticket` (empty `$ARGUMENT`) runs the skill's **Summary Mode** instead: report the queue, write nothing. Normalize the manual input and build one shared discovery packet before planning; reuse its evidence and answered decisions throughout the run. The main agent owns any necessary questions, each prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`. Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
