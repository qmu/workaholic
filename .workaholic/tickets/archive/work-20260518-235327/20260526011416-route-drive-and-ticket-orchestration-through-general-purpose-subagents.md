---
created_at: 2026-05-26T01:14:16+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash: 11b784a
category: Changed
depends_on:
---

# Route Drive and Ticket Orchestration Through general-purpose Subagents

## Overview

The `/drive` and `/ticket` workflows each fan out to a per-workflow Task-subagent agent file: `/drive` invokes `work:drive-navigator`, and `/ticket` invokes `work:ticket-organizer`, which in turn invokes `work:discoverer` three times in parallel. As with the report flow, these agent files are thin shells that preload a `core` skill where the real knowledge lives (`core:drive` Navigator section, `core:create-ticket` Workflow, `core:discover`). This ticket repoints both commands so they spawn `subagent_type: "general-purpose"` subagents that preload the matching `core` skill section, eliminating the need for the three agent `.md` files.

Two structural constraints drive the design:

1. **A subagent cannot nest `Task` calls** (verified this session). `ticket-organizer` is itself a subagent that fans out three `work:discoverer` calls — that nested fan-out must move up to the `/ticket` **command** (main agent), which spawns the three general-purpose discovery subagents directly.
2. **A subagent cannot call `AskUserQuestion`.** `drive-navigator` presents the ticket-order confirmation dialog and the icebox/stop choices; those interactions must move to the `/drive` **command** (main agent). The navigator's pure list/analyze/prioritize logic can run in a leaf general-purpose subagent (or inline in the command), but every `AskUserQuestion` must be issued by the command.

This is the second of three tickets in the campaign to make `work` thin. It mirrors the pattern the report-flattening ticket establishes, and must land before the agent-file deletion ticket (which removes `drive-navigator.md`, `ticket-organizer.md`, and `discoverer.md` along with the seven report agents).

## Key Files

- `plugins/core/skills/drive/SKILL.md` - The drive skill. `## Command Workflow → Phase 1: Navigate Tickets` invokes `work:drive-navigator`; the `## Navigator` section is the body that subagent runs and contains `AskUserQuestion` calls (order confirmation, icebox/stop) that cannot run in a subagent. `## Command Workflow` also has inline `ls -1 .workaholic/tickets/todo/*.md` calls (Phase 3, Navigator section) that violate the Shell Script Principle — fix opportunistically.
- `plugins/work/commands/drive.md` - Thin `/drive` command (13 lines). Preloads `core:drive`, follows Command Workflow. After this ticket, Phase 1 must either run navigation inline at command level (since it needs AskUserQuestion) or spawn a leaf general-purpose subagent for the list/prioritize step and issue the AskUserQuestion at command level.
- `plugins/core/skills/create-ticket/SKILL.md` - The create-ticket skill. `## Workflow → ### 2. Parallel Discovery` invokes `work:discoverer` three times; this nested fan-out must move to the `/ticket` command (main agent). The skill already documents "Skills cannot invoke subagents... the steps below describe what the loading agent must do" — reuse that framing for general-purpose.
- `plugins/core/skills/discover/SKILL.md` - Discoverer's knowledge (history/source/policy modes, each with its own output schema). Unchanged, but referenced by the new general-purpose discovery prompts.
- `plugins/work/commands/ticket.md` - The `/ticket` command (49 lines — already thicker than the others because it does branch guard + AskUserQuestion handling). Currently invokes `work:ticket-organizer`. After this ticket, the command runs the create-ticket Workflow at main-agent level: branch check, spawn three parallel general-purpose discoverers, handle moderation/clarification with AskUserQuestion, write tickets. Note: ticket-organizer's "Never use AskUserQuestion (the command relays decisions)" contract already assumes the command owns user interaction — this ticket completes that split.
- `plugins/work/agents/drive-navigator.md` - 21-line shell preloading `core:drive`; dereferenced by this ticket (deleted in the dependent cleanup ticket).
- `plugins/work/agents/ticket-organizer.md` - 32-line shell preloading `core:branching` + `core:create-ticket` + `core:gather`; dereferenced here. NOTE: this organizer agent file's prose is what was supplied as the operative instruction set when authoring these very tickets — confirm the command-level replacement preserves its CRITICAL guardrails (never implement, never commit, tickets only under `tickets/{todo,icebox}/`).
- `plugins/work/agents/discoverer.md` - 31-line shell preloading `core:discover` with mode routing; dereferenced here.

## Related History

This continues the same flatten-the-graph campaign as the report-flattening ticket. Prior tickets already thinned the drive and ticket-organizer umbrellas into `core` skills; the present ticket finishes the job by removing the subagent layer those skills still route through. The established safe sequence — move knowledge into the skill, repoint the command, then delete the dereferenced agent — is reused.

Past tickets that touched similar areas:

- [20260514154650-thin-drive-umbrella-into-core-skill.md](.workaholic/tickets/archive/work-20260417-092936/20260514154650-thin-drive-umbrella-into-core-skill.md) - Folded drive orchestration into `core:drive` (same skill rewired here)
- [20260514154744-thin-ticket-organizer-and-command-into-create-ticket-skill.md](.workaholic/tickets/archive/work-20260417-092936/20260514154744-thin-ticket-organizer-and-command-into-create-ticket-skill.md) - Moved ticket-organizer knowledge into `core:create-ticket` and established the command-owns-AskUserQuestion split this ticket completes
- [20260514154749-thin-ship-and-discover-umbrellas.md](.workaholic/tickets/archive/work-20260417-092936/20260514154749-thin-ship-and-discover-umbrellas.md) - Thinned the discover umbrella (same `core:discover` referenced by the new general-purpose discovery prompts)

## Implementation Steps

1. **Rewrite `core:create-ticket` Step 2 (Parallel Discovery) to spawn general-purpose subagents.** Replace "Invoke `work:discoverer` three times in parallel" with: the loading agent (the `/ticket` command, main-agent context) issues three parallel `subagent_type: "general-purpose"` Task calls in a single message (`model: opus`), each preloading `core:discover` and running one mode (history / source / policy), each returning its mode's output schema. Keep the "wait for all three" and the moderation-handling steps. The skill prose continues to address its loading agent ("the steps below describe what the loading agent must do").

2. **Rewrite `core:create-ticket` Workflow framing** so it no longer says "Followed by `work:ticket-organizer`." It now says the `/ticket` command (main agent) drives the Workflow directly. Preserve every CRITICAL guardrail verbatim: never implement code, never commit, never AskUserQuestion inside discovery subagents, tickets only under `.workaholic/tickets/{todo,icebox}/`, Allowed Locations section.

3. **Rewrite `plugins/work/commands/ticket.md`** so Step 1 ("Invoke Ticket Organizer") becomes the command running the `core:create-ticket` Workflow itself: branch check (Step 1 of skill), spawn the three parallel general-purpose discoverers (skill Step 2), handle moderation result (Step 3), evaluate complexity and write ticket(s) (Steps 4–5), and relay `needs_decision`/`needs_clarification` via AskUserQuestion (Step 6). The command already owns the AskUserQuestion relay and the commit step — keep those. The command preloads `core:create-ticket`, `core:branching`, `core:gather` (move these from ticket-organizer's frontmatter to the command's `skills:` frontmatter so they are in scope). Keep the command reasonably thin by leaning on the skill for all knowledge.

4. **Rewrite `core:drive` Navigator section to be command-runnable, moving AskUserQuestion to the command.** Split the Navigator section's responsibilities: (a) list + analyze + prioritize tickets (read frontmatter, dependency topo-sort, severity/context grouping) is pure logic that can run in a leaf `general-purpose` subagent OR inline at command level; (b) the order-confirmation dialog, the icebox/stop choice, and the "work on icebox" prompt are `AskUserQuestion` calls that MUST run at command level. Recommended split: the command spawns a `general-purpose` subagent (preload `core:drive`, run the list/analyze/prioritize logic, return the proposed ordered ticket list + tier grouping as JSON), then the command presents the AskUserQuestion confirmation and resolves the final order. Document this split explicitly in the Navigator section.

5. **Rewrite `core:drive` Phase 1 (Navigate Tickets)** to replace the `subagent_type: "work:drive-navigator"` invocation with the command-level flow from step 4: spawn the general-purpose prioritizer, then the command issues the confirmation AskUserQuestion. Preserve the status handling (`empty`/`stopped`/`icebox`/`ready`) — but the `icebox` and `stopped` outcomes now result from command-level AskUserQuestion, not a subagent return.

6. **Update `plugins/work/commands/drive.md`** to note that navigation user-interaction happens at command level (keep it thin). Ensure `core:drive` remains preloaded.

7. **Fix the inline shell in `core:drive` opportunistically.** The Navigator and Phase 3 sections use inline `ls -1 .workaholic/tickets/todo/*.md 2>/dev/null` and `ls -1 .workaholic/tickets/icebox/*.md`, plus inline `mv ... && git add ...` for icebox moves — these violate the Shell Script Principle. Extract them into bundled scripts under `plugins/core/skills/drive/scripts/` (e.g., `list-todo.sh`, `list-icebox.sh`, `promote-icebox.sh`) and reference via `${CLAUDE_PLUGIN_ROOT}`. (If the developer prefers to keep this ticket scoped to the subagent refactor, this step can be deferred to a separate housekeeping ticket — flag at approval.)

8. **Do NOT delete the agent files in this ticket.** `drive-navigator.md`, `ticket-organizer.md`, `discoverer.md` stay on disk until the dependent cleanup ticket removes them. This ticket only stops `core:drive`, `core:create-ticket`, `/drive`, and `/ticket` from *referencing* them.

9. **Verify no remaining `work:` drive/ticket-agent references in the rewritten files:**
   ```bash
   grep -n 'work:drive-navigator\|work:ticket-organizer\|work:discoverer' plugins/core/skills/drive/SKILL.md plugins/core/skills/create-ticket/SKILL.md plugins/work/commands/drive.md plugins/work/commands/ticket.md
   ```
   Expected: no output.

## Final Report

Development completed as planned. Both `/drive` and `/ticket` now fan out at command (main-agent) level: `/ticket` spawns three `general-purpose` discovery subagents directly (no `ticket-organizer`), and `/drive` spawns a `general-purpose` prioritizer then issues every navigation AskUserQuestion itself (no `drive-navigator`). The nested-Task anti-pattern (`ticket-organizer` spawning three `discoverer`s) is gone — one-level fan-out only. Step 7 (inline-shell extraction) was done in this ticket rather than deferred: `list-todo.sh`, `list-icebox.sh`, and `promote-icebox.sh` were added under `plugins/core/skills/drive/scripts/`, smoke-tested, and referenced via `${CLAUDE_PLUGIN_ROOT}`. Step-9 grep returns no `work:` drive/ticket-agent references. Agent `.md` files left on disk for 011417.

### Discovered Insights

- **Insight**: The Navigator's responsibilities had to be split by capability, not convenience — prioritization logic (topo-sort, severity, grouping) is non-interactive and runs in a leaf subagent, but the order-confirmation, empty-queue, and icebox-selection dialogs are all AskUserQuestion and must run at command level. The skill now documents this split explicitly ("Prioritizer Output" replaces "Navigator Output").
  **Context**: Any future edit that moves an AskUserQuestion into the prioritizer subagent prompt breaks `/drive` silently — subagents cannot call AskUserQuestion. The capability boundary is the design constraint, not a style choice.
- **Insight**: The `/ticket` command necessarily grew (skills frontmatter + a multi-step Workflow runner) because branch guard + discovery fan-out + moderation + complexity + AskUserQuestion relay all converge there. It stays thin by delegating all knowledge to `core:create-ticket` — the command is orchestration steps, not duplicated heuristics.
  **Context**: This is the expected shape for the thinned `work` plugin: commands are orchestration shells that preload `core` skills; the "thin command" goal means no per-workflow agent files, not minimal command line-count.

## Considerations

- **AskUserQuestion must never appear in a general-purpose subagent prompt.** Subagents cannot call it (verified). Every interactive decision in the drive/ticket flows — order confirmation, icebox/stop, merge/split decisions, clarification questions, abandonment — must be issued by the command (main agent). The leaf general-purpose subagents only do non-interactive work (discovery, prioritization logic) and return JSON for the command to act on. (`plugins/core/skills/drive/SKILL.md` Navigator section, `plugins/core/skills/create-ticket/SKILL.md` Step 6.)
- **One-level fan-out only.** `ticket-organizer`'s current nested fan-out (subagent spawning three discoverers) is exactly the anti-pattern being removed. After this ticket the `/ticket` command spawns the three discoverers directly; no subagent spawns subagents. (`plugins/core/skills/create-ticket/SKILL.md` Step 2.)
- **The `/ticket` command will grow** beyond the current ~49 lines because branch guard + discovery fan-out + moderation handling + complexity evaluation + AskUserQuestion relay all move to command level. This is acceptable per the campaign goal (thin = no per-workflow agent files), but keep the command leaning on `core:create-ticket` for all knowledge; the command should be orchestration steps, not duplicated heuristics. (`plugins/work/commands/ticket.md`.)
- **Preserve discoverer mode schemas.** Each discovery mode (history/source/policy) returns a distinct JSON schema consumed by different create-ticket sections (Related History, Key Files/Patches, Considerations). The three general-purpose prompts must each name the correct `core:discover` section and its output schema so the command can populate the ticket correctly. (`plugins/core/skills/discover/SKILL.md` output schemas.)
- **Drive navigator prioritization is non-trivial** (dependency topo-sort with cycle detection, severity ranking, context grouping). Keep this logic in the `core:drive` Navigator section so the general-purpose prioritizer subagent preloads it; do not inline-summarize it in the command. (`plugins/core/skills/drive/SKILL.md` Navigator section, "Determine Priority Order".)
- **This is a `Config`-layer plugin-architecture change** governed by the CLAUDE.md architecture policy and the workaholic.md rule. No runtime behavior of the produced tickets or drive commits changes; only the orchestration topology and user-interaction placement move. The Shell Script Principle applies to all rewritten prose (no inline conditionals/pipes); step 7 actively improves compliance.
- **Dependency note**: This ticket and the report-flattening ticket (`20260526011415-...`) are independent and may proceed in parallel. The agent-file deletion ticket (`20260526011417-...`) depends on BOTH because it deletes `drive-navigator.md` / `ticket-organizer.md` / `discoverer.md` (this ticket's agents) plus the seven report agents only after every caller is repointed.
