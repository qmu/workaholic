---
name: drive
description: Interactively survey the claimable missions and unclaimed backlog, ask which units to take, then claim, implement, and route each by merge policy.
skills:
  - workaholic:drive
  - workaholic:story
  - workaholic:ship
---

# Drive

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end. This is the **attended** entry point: when the survey offers more than one claimable or resumable target, ask once — `multiSelect`, the body prefixed with `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` — which to take (skill §2); nothing else is ever asked at any step, and no gate is ever overridden. `$ARGUMENTS`, when present, names one unit (a mission slug or a ticket path) — a scope, not a mode. Landing a claimed unit (`land-unit.sh <unit-id> --developer-present`, skill §6's third route) is a separate, developer-issued act, never a step of this run. End with the reconciliation line and the terminal token derived from the skill's §7 table; a caller-side loop must name `/implement`, not this command.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
