---
type: Feedback
title: A freshly-installed plugin is not invocable until /reload-plugins, which no unattended routine ever types
kind: instruction
source: discussion
created_at: 2026-08-07T10:40:46+00:00
author: a@qmu.jp
supersedes: 
---

# A freshly-installed plugin is not invocable until /reload-plugins, which no unattended routine ever types

# A freshly-installed plugin is not invocable until /reload-plugins, which no unattended routine ever types

Measured on the [Implement] routine (2026-08-07, driving qmu/workaholic#291 and #300's tickets): the web bootstrap's `session-start.sh` reported `workaholic installed. Run /reload-plugins if its commands aren't available yet.` and `check-deps/scripts/check.sh` reported `ok: true`, but calling `Skill({skill: "workaholic:drive"})` failed with `Unknown skill: workaholic:drive` — the plugin's commands and namespaced skills were not registered in the running session at all. The script's own comment already names the cause: "a plugin installed during SessionStart is not active until /reload-plugins and the developer has to be told" (bootstrap/session-start.sh). That sentence assumes a developer is present to read the line and type `/reload-plugins`. An unattended [Implement]/[Propose] routine has nobody to read it, so the session is left with the plugin's files on disk but none of its commands, skills, or hooks live — for the whole run, not just the first turn.

The session worked around it by reading each skill's SKILL.md directly and invoking its bundled bash scripts one at a time (survey → claim → drive → report → route), reproducing `/implement`'s Unified Run by hand instead of running the actual command. That is fragile: it depends on the operator session already knowing the skill's internal script sequence, and a less-informed session would have simply stopped at "the workaholic plugin must be loaded" or produced incorrect ad-hoc behavior instead.

This affects every first-run web routine session where SessionStart's fast-install path actually installs or updates the plugin (not just the already-covered case of a superseded cached binding) — i.e. anytime the container image's baked-in plugin is missing or stale enough that `session-start.sh` does real work. Worth investigating whether the harness can auto-reload after a SessionStart-triggered install (or run the install synchronously before the harness finalizes its command/skill registry), since a routine cannot type `/reload-plugins` itself and the plugin cannot inject that keystroke into its own session.
