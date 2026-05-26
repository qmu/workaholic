---
created_at: 2026-05-27T01:23:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
depends_on: [20260527012300-decouple-core-ship-from-trip.md]
category:
---

# Make workflow-skill orchestration prose agent-neutral

## Overview

The workflow skills (`create-ticket`, `drive`, `report`, `ship`) describe their orchestration in **Claude-Code-specific** terms: spawning `subagent_type: "general-purpose"` Task subagents for fan-out, and `AskUserQuestion` for every decision/approval dialog. On Codex and other agents these primitives do not exist, so a skill that instructs "spawn three general-purpose subagents" is unrunnable there.

This ticket rewrites the orchestration prose so it describes the **workflow** in agent-neutral language, with the Claude-Code fan-out and dialog mechanisms expressed as *optional enhancements*. The intent (per the developer): in Claude Code these remain slash commands using subagents and `AskUserQuestion`; on other agents the same skill is invoked and the agent performs the steps directly (sequentially) and asks the user in plain chat. Same outcome, no Claude-only primitive required.

## Key Files

- `plugins/core/skills/report/SKILL.md` - Heaviest: "spawns its workers as `general-purpose` subagents", Phase 2 "spawn 3 general-purpose leaf subagents", the carry-over judge / PR / release-note subagent spawns. Rewrite so the *sections* (overview, section-review, release-readiness, PR creation, release note) are described as steps; "in Claude Code, run these in parallel as general-purpose subagents; otherwise perform them in sequence."
- `plugins/core/skills/create-ticket/SKILL.md` - Step 2 "spawn three `general-purpose` discovery subagents", Step 3/6 `AskUserQuestion` for moderation/clarification. Rewrite: "gather history/source/policy discovery (in Claude Code, as three parallel subagents; otherwise sequentially); ask the user to decide via the agent's native prompt."
- `plugins/core/skills/drive/SKILL.md` - Navigate/approve flow uses `AskUserQuestion` (order confirmation, approve/abandon, icebox) and a general-purpose prioritizer subagent. Rewrite to "present the plan and ask the user to confirm" in agent-neutral terms; Claude-specific prioritizer subagent as an enhancement.
- `plugins/core/skills/ship/SKILL.md` - Post-decouple ship essence; remove any `AskUserQuestion`-only phrasing from the portable path (e.g. deploy confirmation) into agent-neutral "ask the user to confirm."
- `plugins/core/skills/review-sections/SKILL.md` - **Has no YAML frontmatter at all** (Codex requires `name`+`description`). Add valid frontmatter. (Flagged by the Codex readiness assessment.)
- `plugins/work/commands/{ticket,drive,report,ship}.md` - The Claude-Code commands stay thin and may keep naming the subagent/AskUserQuestion enhancements; the portable *skill* prose must not depend on them.

## Related History

- [20260526011415-flatten-report-orchestration-to-general-purpose-subagents.md](.workaholic/tickets/archive/work-20260518-235327/20260526011415-flatten-report-orchestration-to-general-purpose-subagents.md) - Established the general-purpose-subagent fan-out language now being made agent-neutral.
- [20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md](.workaholic/tickets/archive/work-20260518-235327/20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md) - Moved AskUserQuestion + fan-out to command level; this ticket makes the skill bodies themselves agent-neutral.

## Implementation Steps

1. **Adopt a consistent agent-neutral pattern.** For fan-out: describe the independent units of work and add "In Claude Code, run these in parallel as `general-purpose` subagents; on other agents, perform them sequentially." For interaction: "Ask the user to <decide X>" (agents map this to their native prompt; Claude Code uses `AskUserQuestion`).
2. **Rewrite `report`** sections accordingly (the densest case), preserving the exact outputs each step produces.
3. **Rewrite `create-ticket`** discovery + moderation/clarification prose.
4. **Rewrite `drive`** navigation/approval prose; keep the deterministic guards (worktree/branch/system-safety) intact.
5. **Rewrite `ship`** (post-decouple essence) confirmation prose.
6. **Add frontmatter to `review-sections/SKILL.md`** (`name: review-sections`, a proper `description`). It is referenced by `report`'s closure, so it must be a valid discoverable skill.
7. **Verify Claude Code parity**: the rewritten skills must still drive `/ticket`/`/drive`/`/report`/`/ship` correctly in Claude Code (commands keep the subagent/AskUserQuestion enhancements).

## Considerations

- **Do not degrade the Claude Code experience.** Parallel fan-out and rich `AskUserQuestion` dialogs are valuable; keep them as the Claude path. Agent-neutral ≠ lowest-common-denominator for Claude — it means the *skill* doesn't *require* them.
- **Approval/interaction must still happen on every agent.** The drive approval gate and ticket moderation are not optional; only the *mechanism* (AskUserQuestion vs plain chat prompt) varies.
- **Depends on ship decoupling** (`20260527012300`) so ship's prose is rewritten in its trip-independent form.
- **Pairs with the build step** (`20260527012301`): prose makes orchestration portable, the build step makes scripts portable; both are needed before the Codex manifest ticket can expose runnable skills.
- **`Config`-layer**; engages `standards:leading-accessibility` (the interaction prose should not assume one agent's modal UI) and `standards:leading-validity` (each step's inputs/outputs stay explicit so sequential execution yields the same result as parallel).
