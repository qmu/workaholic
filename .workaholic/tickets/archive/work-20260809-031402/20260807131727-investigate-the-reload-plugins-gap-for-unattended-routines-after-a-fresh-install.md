---
created_at: 2026-08-07T13:17:27+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260807104046-a-freshly-installed-plugin-is-not-invocable-until-reload-plugins-which-no-unattended-routine-ever-types.md]
merge_policy:
claim: work-20260809-031402
---

# Investigate the /reload-plugins gap for unattended routines after a fresh install

## Overview

A freshly-installed plugin is not invocable until `/reload-plugins` runs, but no
unattended routine ever types that command. Measured on an `[Implement]` run
(2026-08-07): `session-start.sh` installed the plugin and printed "Run
/reload-plugins if its commands aren't available yet," but the very next
`Skill({skill: "workaholic:drive"})` call failed with `Unknown skill:
workaholic:drive` — nothing from the plugin (commands, skills, hooks) was
registered for the rest of that session. The workaround was calling the
skill's bundled bash scripts directly instead of running `/implement` as a
real command, which only works when the operator already knows the internal
script sequence.

This is a **different** failure mode from the already-investigated
"superseded cached binding" gap documented in `workaholify`'s bootstrap
section (`check-deps/scripts/check.sh`'s `registry_version` /
`loaded_version_behind_registry`, closed 2026-08-05): that case is a session
bound to a stale-but-present install. This case is a session where
`session-start.sh` did real install/update work and the harness never
re-registered the result at all, so the plugin's files exist on disk with
none of its commands, skills, or hooks live for the whole run.

Investigate whether the harness offers any way to make a SessionStart-time
install effective without a `/reload-plugins` keystroke (a documented
mechanism, an env var, running the install synchronously before the
harness finalizes its command/skill registry), or whether — as with the
superseded-binding case — there is no in-plugin repair and the honest
answer is to make the condition **legible** instead: detect "the plugin
was just installed/updated by this SessionStart but no reload has
happened" and degrade loudly (e.g. `check-deps/scripts/check.sh` reporting
a distinct reason, and `/implement`'s survey terminating `pending` on it)
rather than continuing to run a session with zero workaholic surface.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a failure must be legible, not silent

## Key Files

- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — installs/updates the plugin at SessionStart; already documents the developer-facing "/reload-plugins" line this ticket investigates working around
- `plugins/workaholic/skills/check-deps/scripts/check.sh` — reports `version`, `checkout_version`, `registry_version` and drift reasons; the natural place to add a "just installed, not yet reloaded" signal if no harness-level fix exists
- `plugins/workaholic/skills/drive/SKILL.md` and `commands/implement.md` — the Unified Run's own precondition surface, which already terminates `pending` on related drift conditions

## Implementation Steps

1. Reproduce the gap in a fresh-install scenario and confirm exactly which harness signal (if any) distinguishes "just installed this SessionStart, not yet reloaded" from "already loaded and working."
2. Determine whether the harness exposes a supported mechanism to make a SessionStart plugin install effective without a human-typed `/reload-plugins` (check Claude Code docs/CLI behavior; do not guess).
3. If a mechanism exists: wire `session-start.sh` (or the harness config) to use it, so an unattended routine's first turn has the plugin's commands/skills/hooks live.
4. If no mechanism exists: extend `check-deps/scripts/check.sh` to report the condition explicitly (a new field/reason, following the existing `version_drift`/`registry_version` pattern), and have `/drive` and `/implement` terminate `pending` on it rather than silently failing mid-run with `Unknown skill: ...`.
5. Update `workaholify`'s bootstrap documentation (`CLAUDE.md`'s `/workaholify` row and the bootstrap skill) with whichever outcome is reached, following the same "legible, not gated" precedent already recorded for the superseded-binding case.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The investigation's outcome (fixed vs. no-fix-legible-degradation) is recorded in the relevant skill/doc, following the existing precedent for the superseded-binding gap
- An unattended routine session that hits this condition never silently proceeds with zero workaholic surface — it either works, or reports the condition and stops `pending`

**Verification method** — the commands/tests/probes that prove them:

- If a harness-level fix is found: reproduce the original failure scenario and confirm `Skill({skill: "workaholic:drive"})` succeeds on the same turn a fresh install happens
- If no fix exists: exercise `check-deps/scripts/check.sh` against a simulated fresh-install state and confirm it reports the new condition, and confirm `/drive`/`/implement` terminate `pending` on it

**Gate** — what must pass before approval:

- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` pass
- Documentation (`CLAUDE.md`, the affected skill) reflects whichever outcome was reached, in the same change

## Considerations

- This may turn out, like the superseded-binding case, to have no fix inside the plugin — the deliverable is then documentation plus a legibility improvement, not a workaround
- Scope this to the fresh-install case only; do not fold in or re-litigate the already-closed superseded-cached-binding investigation

## Final Report

**Reproduced live, in this very session.** This ticket was driven by a Claude Code Web session
that itself hit the exact gap: the SessionStart hook's `workaholic installed. Run /reload-plugins
if its commands aren't available yet.` line printed, and the session's very next
`Skill({skill: "workaholic:notify"})` call failed `Unknown skill: workaholic:notify`. Nothing from
the plugin (commands, skills, hooks) was live for the rest of the session — the workaround was
calling the skill's bundled scripts directly via Bash, exactly as the Overview describes.
`CLAUDE_PLUGIN_ROOT` was confirmed unset for the whole run.

**No harness mechanism exists (Step 2, checked against documentation, not guessed).** Consulted
Claude Code's own docs
(https://code.claude.com/docs/en/plugins-reference.md#plugin-updates-and-caching): "When a plugin
updates mid-session, hook commands, monitors, MCP servers, and LSP servers keep using the previous
version's path. Run `/reload-plugins` to switch..." — `/reload-plugins` is the *only* documented
way to make a plugin update effective mid-session, and it is a manual, human-invoked command.
There is no environment variable, CLI flag, settings.json option, or alternate hook event that
makes a SessionStart-time install effective before the harness finalizes its command/skill
registry. This is the same conclusion the already-closed superseded-binding investigation reached
for its own axis, now confirmed for this different one: **no fix inside the plugin (Step 3 does
not apply); the deliverable is the legibility improvement Step 4 describes.**

**Legibility implemented (Step 4).** `check-deps/scripts/check.sh` now reports three new fields —
`claude_session_detected` (a genuine Claude Code session, via `CLAUDE_CODE_SESSION_ID`),
`registry_has_install` (the harness's own registry confirms this plugin is installed, read
independently of whether a root was bound), and `unbound_in_claude_session` (true when
`loaded_root_source == "none"` and both of the above hold) — distinguishing "installed per the
registry but never bound this session" from "never installed" and from "a non-Claude agent/bare
checkout, which has no root by design." Verified directly against this session: running the
patched script here reports `unbound_in_claude_session: true`, confirming the detector fires on
the exact live case that motivated it. `drive/SKILL.md` §1 and its `reference/survey.md` now
terminate `pending` on it, identically to the existing registry-drift stop, and the §7 terminal
table gained a matching row.

**Docs updated in the same change (Step 5)**: `CLAUDE.md`'s `/workaholify` row, `workaholify/SKILL.md`'s
web-bootstrap section (a pointer noting a hook-registered install and a *bound* one are different
questions), and `check-deps/SKILL.md` (the axis renamed "Two drift axes" → "Three drift axes" with
the new axis's rationale and known limit spelled out) — following the same "legible, not gated"
precedent already recorded for the superseded-binding case.

### Discovered Insights

- **Insight**: The three environment facts that make the new detector trustworthy —
  `CLAUDE_CODE_SESSION_ID` (proves this is a Claude Code session), the harness's own
  `installed_plugins.json` (proves an install exists), and `loaded_root_source` (already computed,
  proves nothing was bound) — are all facts *about* the harness, never about the plugin's own
  content. This is the same "neither operand is plugin content" property that makes the
  registry-drift axis trustworthy at any plugin age, applied to a new question.
  **Context**: Any future harness-binding diagnostic in this script should keep that property —
  reading plugin content to diagnose a plugin-binding problem risks the reporter agreeing with
  itself, which is exactly the defect the registry axis was built to avoid.
- **Insight**: The detector has a real, named false-positive case — a developer invoking
  `check.sh` directly by its literal path in an otherwise-healthy, fully-bound session also shows
  `loaded_root_source: "none"` for that one call, because the `${CLAUDE_PLUGIN_ROOT}` substitution
  happens in command-body text, never as a persistent process env var.
  **Context**: Accepted deliberately, matching this script's existing bias throughout: an
  unanswerable or ambiguous signal reports the stop, not silence, because the cost of a spurious
  `pending` is far lower than the cost of a routine running its whole tick with zero plugin
  surface and reading as healthy.
