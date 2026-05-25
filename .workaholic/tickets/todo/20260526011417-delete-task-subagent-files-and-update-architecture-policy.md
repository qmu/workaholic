---
created_at: 2026-05-26T01:14:17+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260526011415-flatten-report-orchestration-to-general-purpose-subagents.md, 20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md]
---

# Delete Task-Subagent Files and Update Architecture Policy

## Overview

The two preceding tickets repoint every caller of the ten per-workflow Task-subagent agent files onto `subagent_type: "general-purpose"` subagents that preload `core` skills. This ticket finishes the campaign: it deletes the now-dereferenced agent `.md` files, and updates the project's architecture policy and documentation to codify the new pattern — commands (and the skills they preload) spawn `general-purpose` subagents; named agent files are reserved exclusively for the Agent Teams members `/trip` requires.

The ten files to delete (all in `plugins/work/agents/`): `drive-navigator`, `story-writer`, `section-reviewer`, `overview-writer`, `release-readiness`, `pr-creator`, `release-note-writer`, `carryover-judge`, `ticket-organizer`, `discoverer`. After deletion, `plugins/work/agents/` contains only the three Agent Teams members — `planner`, `architect`, `constructor` — which `/trip` launches as team members (not Task subagents) and which are explicitly exempt from this refactor.

This ticket also revises `CLAUDE.md`'s Component Nesting Rules (skills/commands may now spawn `general-purpose` subagents; the prior Skill→Subagent prohibition is deliberately lifted), adds a "no per-workflow agent files" convention and a one-level fan-out rule, and updates `work/README.md` plus any other docs that enumerate the deleted agents.

## Key Files

- `plugins/work/agents/drive-navigator.md`, `story-writer.md`, `section-reviewer.md`, `overview-writer.md`, `release-readiness.md`, `pr-creator.md`, `release-note-writer.md`, `carryover-judge.md`, `ticket-organizer.md`, `discoverer.md` - The ten Task-subagent files to delete with `git rm`.
- `plugins/work/agents/planner.md`, `architect.md`, `constructor.md` - The three Agent Teams members; KEPT. Must remain after deletion. The decision that `/trip` is intrinsically Agent-Teams-based and stays Claude-Code-only is settled and not re-opened here.
- `CLAUDE.md` - Architecture Policy section. `### Component Nesting Rules` table (lines 34–40) currently lists Skill → "Cannot invoke: Subagent, Command" and Subagent → "Cannot invoke: Command"; the Skill→Subagent prohibition is being lifted for `general-purpose`. `### Design Principle` (lines 62–70) and the project-structure block (the `work/` `agents/` comment around lines 23–28) also reference the deleted agents and need updates. The Component Nesting table must distinguish `general-purpose` subagents (spawnable by commands and skill-driven main agents) from named Agent Teams agents (reserved for `/trip`).
- `plugins/work/README.md` - `## Agents → ### Drive Agents` table (lines ~28–38) lists six of the deleted agents (`drive-navigator`, `discoverer`, `ticket-organizer`, `story-writer`, `pr-creator`, `release-readiness`). The whole "Drive Agents" subsection must be removed or replaced with a note that drive/report/ticket orchestration uses `general-purpose` subagents preloading `core` skills; the "Trip Agents" subsection (planner/architect/constructor) stays.
- `.claude-plugin/marketplace.json` - Verify it does not enumerate per-agent entries (the prior dead-agent-deletion ticket found it does not; re-confirm).
- `plugins/work/.claude-plugin/plugin.json` - Does not name agents; no change expected (re-confirm).
- `plugins/work/hooks/`, `plugins/work/rules/` - Kept as plugin infrastructure (settled decision). Verify they contain no references to the deleted agent names.

## Related History

This ticket is the deletion stage of the flatten-the-graph campaign, directly modeled on the prior dead-agent-deletion ticket which removed five zero-caller agents plus their orphan skills and updated `CLAUDE.md` inventory lines and `.claude/rules/`. That ticket established the discipline this one reuses: run a repo-wide verification grep before committing, treat `.workaholic/` matches as historical and acceptable, and treat any live `plugins/` / `CLAUDE.md` / `.claude/` match as a blocker.

Past tickets that touched similar areas:

- [20260514150430-delete-dead-agents-and-orphan-skills.md](.workaholic/tickets/archive/work-20260417-092936/20260514150430-delete-dead-agents-and-orphan-skills.md) - Deleted zero-caller agents and updated CLAUDE.md/.claude rules; the verification-grep discipline and "move knowledge, repoint, then delete" sequence reused here
- [20260514154737-thin-trip-protocol-umbrella.md](.workaholic/tickets/archive/work-20260417-092936/20260514154737-thin-trip-protocol-umbrella.md) - Thinned the trip protocol; context for why planner/architect/constructor stay as Agent Teams members
- [20260518235327-prohibit-tickets-outside-tickets-dir.md](.workaholic/tickets/archive/work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md) - Recent same-branch ticket touching create-ticket guardrails and the validate-ticket hook (kept infrastructure)

## Implementation Steps

1. **Confirm prerequisites are landed.** Both `depends_on` tickets must be implemented first: `core:report`, `core:drive`, `core:create-ticket`, and the four commands (`report.md`, `drive.md`, `ticket.md`) must no longer reference any of the ten `work:` agent names. If a reference remains, STOP — deleting an agent that still has a caller breaks plugin load.

2. **Run the pre-deletion verification grep** across live files:
   ```bash
   grep -rn 'work:drive-navigator\|work:story-writer\|work:section-reviewer\|work:overview-writer\|work:release-readiness\|work:pr-creator\|work:release-note-writer\|work:carryover-judge\|work:ticket-organizer\|work:discoverer' plugins/ CLAUDE.md .claude/
   ```
   Also grep for bare agent names referenced as `subagent_type`. Expected: no output. Any match under `plugins/`, `CLAUDE.md`, or `.claude/` is a blocker (fix the referring file, which means a `depends_on` ticket was incomplete). Matches under `.workaholic/` are historical and acceptable.

3. **Delete the ten agent files** with `git rm`:
   ```bash
   git rm plugins/work/agents/drive-navigator.md \
          plugins/work/agents/story-writer.md \
          plugins/work/agents/section-reviewer.md \
          plugins/work/agents/overview-writer.md \
          plugins/work/agents/release-readiness.md \
          plugins/work/agents/pr-creator.md \
          plugins/work/agents/release-note-writer.md \
          plugins/work/agents/carryover-judge.md \
          plugins/work/agents/ticket-organizer.md \
          plugins/work/agents/discoverer.md
   ```
   Confirm `plugins/work/agents/` now contains exactly `planner.md`, `architect.md`, `constructor.md`.

4. **Update `CLAUDE.md` Component Nesting Rules.** Revise the table so it reflects the new topology. Suggested shape:
   - Command → can invoke: Skill, `general-purpose` subagent.
   - Skill → can invoke: Skill; and (when loaded by a command/main agent) may direct the loading agent to spawn `general-purpose` subagents. Remove the blanket "Cannot invoke: Subagent."
   - `general-purpose` subagent → can invoke: Skill (via preload). Cannot invoke: Command, Task (no nesting).
   - Add a row or note clarifying that **named agent files** (planner/architect/constructor) are Agent Teams members invoked only by `/trip`, not Task subagents.
   Add explanatory prose distinguishing `general-purpose` subagents (built-in, no `.md` file, preload skills via prompt) from Agent Teams members.

5. **Add a "No Per-Workflow Agent Files" convention to `CLAUDE.md`** (new subsection under Architecture Policy). State: workflow orchestration does not get dedicated agent `.md` files; commands spawn `subagent_type: "general-purpose"` subagents whose prompts instruct them to preload the relevant `core` skill and run a named section. Named agent files are reserved for Agent Teams members.

6. **Add a "One-Level Fan-Out" rule to `CLAUDE.md`.** State: a subagent cannot nest `Task` calls and cannot call `AskUserQuestion`; therefore all fan-out and all user interaction must occur at the command/main-agent level. No subagent-that-spawns-subagents. Leaf subagents return JSON for the command to act on.

7. **Update the `CLAUDE.md` project-structure block** (`plugins/work/` `agents/` comment) so it lists only `drive-navigator, story-writer, ...` → replaced with the three Agent Teams members (planner, architect, constructor), and note the directory holds Agent Teams members only.

8. **Update `plugins/work/README.md`.** Remove the `### Drive Agents` table; replace with a short note that drive/report/ticket workflows spawn `general-purpose` subagents preloading `core` skills (no per-workflow agent files). Keep `### Trip Agents` (planner/architect/constructor). Update the `## Agents` heading prose accordingly.

9. **Re-confirm manifests are clean.** Verify `.claude-plugin/marketplace.json` and `plugins/work/.claude-plugin/plugin.json` name none of the deleted agents (expected: they don't). Verify `plugins/work/hooks/` and `plugins/work/rules/` reference none.

10. **Run the post-deletion verification grep** identical to step 2. Expected: zero matches in live files. Commit as a single refactoring commit per workaholic convention.

## Considerations

- **The `/trip` Agent Teams members are exempt and MUST survive.** `planner.md`, `architect.md`, `constructor.md` are launched by `/trip` as Agent Teams members, not Task subagents — deleting them would break `/trip`. Double-check the delete list excludes them. (`plugins/work/agents/`.)
- **Deletion ordering is load-bearing.** A Claude Code plugin that names a `subagent_type` with no corresponding agent file will fail at invocation. The `depends_on` ordering guarantees callers are repointed first, but step 2's verification grep is the hard gate — do not delete on a stale checkout where a prerequisite ticket's edits are absent. (`CLAUDE.md` architecture policy; precedent in `20260514150430-delete-dead-agents-and-orphan-skills.md` line 155.)
- **The Component Nesting Rules change is a deliberate policy reversal.** The current table forbids Skill→Subagent; this ticket lifts that for `general-purpose`. The rewrite must be careful not to also bless arbitrary named-subagent nesting — the allowance is specifically: commands and skill-driven main agents spawn `general-purpose` leaf subagents, and those leaves cannot nest further. State the asymmetry explicitly so the one-level-fan-out invariant is not accidentally weakened. (`CLAUDE.md` lines 34–40.)
- **`work` still has no `skills/` directory** so the Cross-Agent Skill Exposure rules (CLAUDE.md lines 53–60) are unaffected; deleting agents does not change what the `skills` CLI exposes. No `metadata.internal` implications. (`CLAUDE.md` line 58.)
- **The validate-ticket hook and rules stay.** `plugins/work/hooks/validate-ticket.sh` and `plugins/work/rules/` are kept as plugin infrastructure (settled decision); they must not be deleted and should be confirmed free of deleted-agent references.
- **Documentation drift risk.** Besides `work/README.md`, grep for the deleted agent names in any other markdown (e.g., root README, `.claude/rules/`) to catch enumerated references that would otherwise dangle. Treat `.workaholic/` matches (archived tickets, stories) as historical — do not edit them.
- **This is a `Config`-layer plugin-architecture change.** Governed by the CLAUDE.md architecture policy (the very policy being amended) and the workaholic.md rule. No runtime behavior changes beyond removing dead files and updating documentation; the workflows already function via general-purpose subagents after the two prerequisite tickets.
- **Dependency note**: This ticket depends on BOTH `20260526011415-...` (report flattening) and `20260526011416-...` (drive/ticket flattening). Neither prerequisite deletes any agent file, so all ten deletions and the policy/doc updates are concentrated here for a single coherent cleanup commit.
