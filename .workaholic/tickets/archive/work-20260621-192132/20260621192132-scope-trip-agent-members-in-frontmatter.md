---
created_at: 2026-06-21T19:21:32+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: db6a4c1
category: Changed
depends_on:
---

# Scope the `/trip` Agent Teams members in frontmatter so `/drive` (and other workflows) never invoke them as subagents

## Overview

During a `/drive` run, the main agent delegated implementation to the **`workaholic:constructor`** agent as a `Task` subagent. That is wrong: Constructor — like Planner and Architect — is a **`/trip` Agent Teams member only**. Per CLAUDE.md's Architecture Policy, the three named members in `plugins/workaholic/agents/` are "launched **only by `/trip`** as Agent Teams members — not as `Task` subagents," and `/drive` must implement directly (main agent) or fan out to **`general-purpose`** subagents.

**Root cause is the `description` frontmatter.** Claude Code's automatic subagent-delegation chooses a `subagent_type` by reading each agent's `description`. The three members' descriptions are generic capability blurbs with no trip-only scoping:

- planner — "Progressive agent for business vision, stakeholder advocacy, and explanatory accountability."
- architect — "Neutral agent bridging business vision and technical implementation through structural coherence and translation fidelity."
- constructor — "Conservative agent for technical ownership, quality assurance, and delivery accountability."

So when `/drive` needs to "implement," the model sees Constructor advertising "technical ownership … delivery accountability" and reasonably picks it. The CLAUDE.md rule that forbids this is prose the delegating model does not necessarily weigh; the **description is the actual selection signal**, which is why the fix must live in frontmatter (per the request: "frontmatter should be modified so that claude code makes no mistake").

**Why a frontmatter rewrite is safe.** `/trip` launches the three members **by name** — `trip-protocol/SKILL.md` (lines ~273-275) and `commands/trip.md` reference `workaholic:planner` / `workaholic:architect` / `workaholic:constructor` explicitly — so trip does **not** depend on the `description` for selection. The `description` is therefore consumed **only** by the auto-delegation path that mis-fired. Repurposing it into an explicit "trip-only, never a subagent" guard fixes the misuse without affecting how `/trip` runs.

## Key Files

- `plugins/workaholic/agents/planner.md` - PRIMARY. Rewrite the `description` frontmatter into a trip-only guard. Leave `name`/`tools`/`model`/`color`/`skills` untouched.
- `plugins/workaholic/agents/architect.md` - PRIMARY. Same.
- `plugins/workaholic/agents/constructor.md` - PRIMARY. Same (this is the one `/drive` wrongly invoked).
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Confirms the members are launched **by name** (lines ~273-275), which is what makes the description-as-guard rewrite safe. Reference only; not edited.
- `plugins/workaholic/commands/trip.md` - Launches the Agent Teams session; references members by name. Reference only.
- `CLAUDE.md` - Architecture Policy ("Named Agent Teams members … launched only by `/trip` … not as `Task` subagents" and "No Per-Workflow Agent Files"). The rule the new descriptions enforce; optionally add a one-line note that the members' descriptions are deliberately scoped guards. Reference / light edit.
- `plugins/workaholic/skills/drive/SKILL.md` - Where the mis-delegation occurred (its Workflow fans out to `general-purpose` leaves). Optional belt-and-suspenders: state explicitly that drive spawns ONLY `general-purpose` subagents and never `planner`/`architect`/`constructor`. Secondary to the frontmatter fix.

## Related History

- [20260526011417-delete-task-subagent-files-and-update-architecture-policy.md](.workaholic/tickets/archive/work-20260518-235327/20260526011417-delete-task-subagent-files-and-update-architecture-policy.md) - Codified the one-level fan-out rule and the Agent Teams exemption for `/trip`'s members (the policy this ticket operationalizes in frontmatter). It established that workflow fan-out uses `general-purpose` leaves and that the only agent `.md` files are the trip members — but it did not scope those members' descriptions to prevent non-trip selection, which is the gap this ticket closes.
- [20260617005257-merge-plugins-into-workaholic.md](.workaholic/tickets/archive/work-20260617-000311/20260617005257-merge-plugins-into-workaholic.md) - The single-plugin merge that fixed the members' namespaces to `workaholic:`; the descriptions were carried over unchanged from the pre-merge era and never scoped.

## Implementation Steps

1. **Rewrite each member's `description`** (`planner.md`, `architect.md`, `constructor.md`) into an unmistakable trip-only guard. Lead with the scope, keep the role essence brief, and name the prohibition. Suggested shape (adapt the role clause per member):
   - planner: `"/trip Agent Teams member — launched ONLY by /trip as a team member, NEVER invoked as a Task or general-purpose subagent (not by /drive, /report, /ship, or any non-trip flow). Progressive role: business vision, stakeholder advocacy, explanatory accountability."`
   - architect: same guard prefix + `"Neutral role: bridges business vision and technical implementation through structural coherence and translation fidelity."`
   - constructor: same guard prefix + `"Conservative role: technical ownership, quality assurance, delivery accountability."`
   Keep each description a single line. Do NOT change `name`, `tools`, `model`, `color`, or `skills`.
2. **Confirm the guard does not break `/trip`.** Verify `trip-protocol/SKILL.md` and `commands/trip.md` still launch the members by their `workaholic:<name>` identity (they do, lines ~273-275) — selection is name-based, so the rewritten description is purely a delegation guard.
3. **(Optional, secondary) Reinforce the drive path.** In `skills/drive/SKILL.md`, state explicitly that the workflow spawns ONLY `general-purpose` subagents and must never spawn `planner`/`architect`/`constructor`; optionally add a one-line note in CLAUDE.md that the members' descriptions are intentionally scoped guards. The frontmatter is the primary, load-bearing fix; this is defense-in-depth.
4. **Verify.** Re-read the three frontmatters and confirm each description now scope-limits. Run `node scripts/build-plugins/build.mjs` and confirm `git status outputs/` stays clean (agents/ is Claude-Code-only and excluded from the cross-agent build), then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs`. No version bump is implied by this change.

## Considerations

- **Implementation policy is the binding lens** (`workaholic:implementation`): this is Config/agent-definition work — `directory-structure` (edit `plugins/`, never `.claude/`) applies. `design`/`operation`/`planning` do not bind (no UX, runtime, or new-feature scope).
- **The description IS the fix surface.** Claude Code's subagent-delegation selects by `description`; a guard placed only in CLAUDE.md prose can be ignored by the delegating model. Putting the scope in the `description` is the only change that directly constrains the selection that mis-fired. This is exactly why the requester said the frontmatter must be modified.
- **Safe because `/trip` selects by name.** Verified the members are launched as `workaholic:planner`/`architect`/`constructor` explicitly, so the description is free to become a guard without changing trip behavior — do not also rename or restructure the agents.
- **Do not invent a non-existent frontmatter field.** The robust lever is the `description` text (the real selection signal), not a speculative `disable-invocation`/`team-only` boolean. If Claude Code later exposes a hard exclusion field for agents, adopt it then as an addition, not a replacement.
- **Agent Teams exemption is unchanged.** The three members stay exempt from the Component Nesting and One-Level Fan-Out tables; this ticket only prevents their selection **outside** a trip and must not introduce new agent files or alter their in-trip roles.
- **`outputs/` is unaffected.** `agents/` is Claude-Code-only and excluded from the `outputs/` cross-agent build, so no regenerate/diff is expected; confirm `git status outputs/` stays clean after `build.mjs`.

## Final Report

Development completed as planned. The primary fix is the frontmatter rewrite of all three members' `description` into trip-only guards; the optional defense-in-depth (step 3) was taken in the drive skill (a new Critical Rule) but **not** in CLAUDE.md (the existing Architecture Policy already states the rule).

### Discovered Insights

- **Insight**: Adding the drive-skill Critical Rule did regenerate `outputs/workflows/skills/drive/SKILL.md` — the drive skill IS in the cross-agent build, so this ticket's "git status outputs/ stays clean" expectation held only for the agent-frontmatter edits, not the drive-skill edit. The agent files themselves never enter `outputs/` (agents/ is Claude-only), exactly as predicted.
  **Context**: Any future edit that touches both a Claude-only file (agents/, commands/, hooks/) and a built skill (create-ticket/drive/report/ship) will produce a partial outputs/ diff — regenerate and commit it. The `publicizeSkillMd` substitution rewrote the guard's "general-purpose subagents" to "parallel workers" in the generated copy, so the cross-agent line reads "fan out to parallel workers only" (harmless on agents that have no /trip).
- **Insight**: The fix relies entirely on `description` being the subagent-selection signal AND `/trip` selecting its members by explicit name. Both were verified (trip-protocol/SKILL.md lines ~273-275 reference `workaholic:planner`/`architect`/`constructor`). If a future change ever made `/trip` select members by description/auto-delegation, these guard descriptions would break trip — so that name-based launch is now a load-bearing invariant worth preserving.
  **Context**: The guard is a soft (model-judgment) constraint, not a hard platform gate — Claude Code exposes no per-agent "exclude from Task" frontmatter field today. The description rewrite plus the drive Critical Rule are the strongest available levers; adopt a hard field if one ships.
