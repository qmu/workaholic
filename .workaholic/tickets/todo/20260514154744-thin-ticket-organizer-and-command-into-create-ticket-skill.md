---
created_at: 2026-05-14T15:47:44+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash:
category:
depends_on:
---

# Thin work-side ticket-organizer and /ticket command by migrating procedural content into core:create-ticket skill

## Overview

The work-side `ticket-organizer` agent (144 lines) and `/ticket` command (68 lines) carry orchestration that belongs in the knowledge layer. Move the procedural content — the discoverer invocation orchestration, moderation-result handling, complexity evaluation, splitting logic, output JSON shapes, and Lead-Lens application — out of the work-side files and into `plugins/core/skills/create-ticket/SKILL.md`. After the move:

- `plugins/work/agents/ticket-organizer.md` shrinks to ~15 lines (frontmatter + I/O contract + "follow Workflow" pointer), matching the shape of the existing thin `discoverer.md` (30 lines).
- `plugins/work/commands/ticket.md` shrinks to ~15 lines (frontmatter + thin alias notice + pre-checks + "delegate to ticket-organizer" pointer).
- `plugins/core/skills/create-ticket/SKILL.md` grows by ~100 lines to host a new `## Workflow` section plus subsections for parallel discovery, moderation handling, complexity evaluation, ticket writing, and output JSON contracts.

The four `standards:leading-*` soft preloads that currently live on the `ticket-organizer` agent move to `core:create-ticket`'s frontmatter `skills:` list. This is allowed by the project's dependency rule that "core CAN soft-depend on standards (skill preloads OK)" and aligns the Lead Lens table (which already documents the layer→lead mapping inside the skill) with the actual preload site. The work-side agent's frontmatter `skills:` list reduces to `core:branching, core:create-ticket, core:gather` (no `standards:leading-*` entries needed, because the skill carries them in scope).

This is a refactor. Current behavior — three parallel discoverer invocations, moderation/duplicate/needs-decision flow, AskUserQuestion presentation for decisions and clarifications, branch creation guard on main, worktree guard with "Continue here / Switch to worktree" choice, dependency pre-check, archive-script-aware commit step — must be preserved exactly. The verification grep in Implementation Step 6 enumerates every script path, AskUserQuestion text, and `subagent_type` slug that must still appear at the new locations.

## Key Files

### Source files (in scope for direct edit)

- `plugins/work/agents/ticket-organizer.md` (144 lines, heaviest agent in the repo) — currently holds Input, Instructions (steps 1-6 with discoverer orchestration), and Output JSON contracts. After the move, body shrinks to ~10 lines stating I/O and pointing to the skill's Workflow section. Frontmatter `skills:` list drops the four `standards:leading-*` entries.
- `plugins/work/commands/ticket.md` (68 lines) — currently holds pre-check, worktree guard, ticket-organizer invocation, response handling, and commit-and-present step. After the move, body shrinks to ~15 lines: frontmatter, thin-alias notice, pre-check, worktree guard, Task-tool invocation pointer, commit step. The Lead Lens note and CRITICAL implementation-prevention notice stay (they are user-visible policy text, not orchestration).
- `plugins/core/skills/create-ticket/SKILL.md` (256 lines) — receives a new `## Workflow` section (and supporting subsections for discovery, moderation, complexity, splitting, output JSON) describing the procedure the ticket-organizer follows. Frontmatter `skills:` list gains `standards:leading-validity`, `standards:leading-accessibility`, `standards:leading-security`, `standards:leading-availability` as soft cross-plugin preloads. `user-invocable: false` stays — the skill is still loaded only via agent preload.

### Reference files (read-only, behavior anchors)

- `plugins/work/agents/discoverer.md` (30 lines) — canonical example of the thin-agent shape: frontmatter + brief Input + Mode Routing table + brief Output. Mirror this shape for the thinned `ticket-organizer.md`.
- `plugins/work/agents/pr-creator.md`, `plugins/work/agents/release-readiness.md` — additional thin-agent precedents. Same pattern: short frontmatter, short body, all knowledge in the preloaded skill.
- `plugins/work/commands/drive.md` (current command pattern with subagent-invocation step) — reference for the post-thinning shape of `ticket.md`. Drive command keeps orchestration in the command (more complex multi-step workflow); ticket command after thinning is even thinner because it has just one subagent to invoke.
- `plugins/core/skills/discover/SKILL.md` — the skill `work:discoverer` follows. Confirms the `subagent_type: "work:discoverer"` slug and the history/source/policy modes. No edits here.
- `plugins/core/skills/gather/SKILL.md` (53 lines) — the ticket-metadata probe the create-ticket skill already references. Confirms `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh` is the canonical script path. No edits.
- `plugins/core/skills/branching/SKILL.md` — the branch-state and topic-branch scripts the workflow must call (`scripts/check.sh`, `scripts/create.sh`). No edits; the Workflow section in create-ticket references these scripts by path.
- `plugins/core/skills/check-deps/scripts/check.sh` — the dependency pre-check the `/ticket` command runs. Path stays in the command (it is a command-level pre-check, not part of the skill workflow). No edits.
- `plugins/work/hooks/validate-ticket.sh` line 9 — points users at `plugins/core/skills/create-ticket/SKILL.md` for guidance. Path is already correct (per prior ticket `20260514121259-move-work-skills-to-core.md`), and the skill remains at that path after this ticket. No edits.

### Reference files (preload contract anchors)

- `plugins/standards/skills/leading-validity/SKILL.md`, `leading-accessibility/SKILL.md`, `leading-security/SKILL.md`, `leading-availability/SKILL.md` — the four leads moving from agent-preload to skill-preload. `user-invocable: false` and `standards:leading-*` invocation slug are the contract.
- `plugins/core/.claude-plugin/plugin.json` — `dependencies: []`. Stays empty after this ticket; the standards preloads are soft cross-plugin references, not hard dependencies. This matches the pattern already used by `work` against `standards`.
- `plugins/work/.claude-plugin/plugin.json` — `dependencies: ["core"]`. Stays unchanged.
- `CLAUDE.md` "Plugin Dependencies" section — describes "work has soft references to standards". After this ticket, core also has a soft reference to standards (skill preloads). Update the diagram/text to reflect this.

## Related History

The codebase has a deep precedent of thinning agents and commands by migrating procedural content into the preloaded skill. The original `/ticket` → `ticket-organizer` refactor (`20260202125814`) established the thin-command pattern that this ticket extends one level further (now thinning the agent itself). The discoverer consolidation (`20260406185951`) is the closest structural analog: it moved three discoverer agent files into a single parameterized `discoverer.md` whose body is ~15 lines and delegates everything to the `discover` skill — the target shape for `ticket-organizer.md` after this ticket. The recent `move-work-skills-to-core` (`20260514121259`) put `create-ticket` in core where this ticket's content migration lands. The leading-skills wiring ticket (`20260509001216`) is where the four `standards:leading-*` preloads were attached to `ticket-organizer`; this ticket relocates them onto the skill, completing the leads' migration into the knowledge layer.

Past tickets that touched similar areas:

- [20260202125814-ticket-command-alias-refactor.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125814-ticket-command-alias-refactor.md) — Original `/ticket` → `ticket-organizer` thinning; established the thin-command pattern this ticket extends to the agent layer (same files modified).
- [20260203200934-refactor-ticket-organizer.md](.workaholic/tickets/archive/drive-20260203-122444/20260203200934-refactor-ticket-organizer.md) — Earlier refactor of the same agent (same file modified).
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) — Introduced the three-parallel-discoverer pattern this ticket preserves (same orchestration moves into the skill).
- [20260406185951-consolidate-discoverer-agents.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406185951-consolidate-discoverer-agents.md) — Closest structural analog: thinned three discoverer agents into one ~30-line parameterized agent (target shape for `ticket-organizer.md`).
- [20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) — Attached the four `standards:leading-*` preloads to `ticket-organizer`; this ticket migrates them to the skill.
- [20260514121259-move-work-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514121259-move-work-skills-to-core.md) — Moved `create-ticket` skill into core (where this ticket's migrated content lands).
- [20260202181910-move-create-branch-to-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181910-move-create-branch-to-ticket-organizer.md) — Established the branch-creation guard inside the ticket-organizer flow (procedural step that this ticket relocates into the skill workflow).
- [20260128002853-extract-create-ticket-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002853-extract-create-ticket-skill.md) — Original extraction of `create-ticket` as a skill; this ticket continues the knowledge-into-skills migration.

## Implementation Steps

1. **Delta analysis of `ticket-organizer.md`.** Confirm the body content that must migrate. The migratable blocks are: Input (lines 20-25), Instructions step 1 Check Branch (lines 29-31), step 2 Parallel Discovery (lines 33-41), step 3 Handle Moderation Result (lines 43-48), step 4 Evaluate Complexity (lines 50-55), step 5 Write Ticket(s) including section-population guidance and splitting logic (lines 57-85), step 6 Handle Ambiguity (lines 87-89), and Output JSON contracts (lines 91-142). The CRITICAL final line (line 144) stays as a one-liner in the thinned agent because it is the non-negotiable agent-level safety invariant. Nothing in `create-ticket/SKILL.md` currently duplicates these blocks; the skill's existing content (frontmatter template, common mistakes, file structure, Lead Lens table, exploring the codebase, patch guidelines, writing guidelines) is reference content, not workflow steps.

2. **Add `## Workflow` section to `plugins/core/skills/create-ticket/SKILL.md`.** Insert immediately after the existing `## Filename Convention` section and before `## File Structure`. The Workflow section has six numbered subsections that mirror the current ticket-organizer steps verbatim (preserving behavior):

   1. **Check Branch.** Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check.sh` (wait — this is a same-plugin reference inside core, so the path is `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh`). If `on_main` is true, create a topic branch via `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh` and record the returned branch name as `branch_created` for the output JSON.
   2. **Parallel Discovery.** Invoke `work:discoverer` three times in parallel via the Task tool (single message, three Task calls), one per mode (`history`, `source`, `policy`). Use `model: "opus"` for each. Pass the full request description plus the mode. Wait for all three to complete. (Note: this is a soft instructional reference from a core skill into a work-namespace subagent. It is valid because the reference is in skill body text consumed by an agent that lives in the work plugin — `ticket-organizer` — not a hard frontmatter dependency. The skill itself does not declare a `work:*` dependency.)
   3. **Handle Moderation Result.** Same three branches as today: `duplicate` → return `status: "duplicate"`; `needs_decision` → return `status: "needs_decision"` with merge/split options; `clear` → proceed to step 4.
   4. **Evaluate Complexity.** Same split/keep-single heuristics; if splitting, 2-4 discrete tickets each independently implementable.
   5. **Write Ticket(s).** Follow the rest of this skill for format. Apply the Lead Lens table (preserved unchanged) to choose which leading skill's policies govern Implementation Steps, Considerations, and Patches. Populate sections from the three discovery JSONs: history → Related History (summary + tickets list); source → Key Files (files list) and Implementation Steps (code_flow); source.snippets → Patches; policy → Considerations (policies, architecture.principles, architecture.dependency_rules). For splits: unique timestamps (+1 second between), first ticket is foundation, populate `depends_on` only where there is a genuine ordering requirement, cross-reference in Considerations.
   6. **Handle Ambiguity.** If ambiguous, return `status: "needs_clarification"` with questions array.

3. **Add `## Output Contract` section to `create-ticket/SKILL.md`.** Insert immediately after the new `## Workflow` section. Contains the four JSON shapes verbatim from `ticket-organizer.md` lines 91-142: `success` (with optional `branch_created`), `duplicate`, `needs_decision`, `needs_clarification`. End with the one-line CRITICAL: "Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion (the command relays decisions/clarifications to the user). Return JSON only."

4. **Add `standards:leading-*` soft preloads to `create-ticket/SKILL.md` frontmatter.** Expand the `skills:` list from `[gather]` to:

   ```yaml
   skills:
     - gather
     - standards:leading-validity
     - standards:leading-accessibility
     - standards:leading-security
     - standards:leading-availability
   ```

   Keep `user-invocable: false`. The four `standards:leading-*` entries are soft cross-plugin references. The core plugin's `dependencies` array stays `[]`; soft preloads tolerate the standards plugin being absent, matching the pattern documented in CLAUDE.md and used by the work plugin today.

5. **Thin `plugins/work/agents/ticket-organizer.md` to ~15 lines.** Replace lines 20-144 with a short body. Reduce frontmatter `skills:` from the current six entries to three (`core:branching`, `core:create-ticket`, `core:gather`) — the four `standards:leading-*` entries move to the skill. Keep `tools: Read, Write, Edit, Glob, Grep, Bash, Task` unchanged: all seven tools are still used. Read is used by the skill workflow for ticket-area exploration; Write/Edit create and adjust ticket files; Glob/Grep support codebase exploration the skill prescribes in its "Exploring the Codebase" section; Bash runs the branching and metadata scripts; Task spawns the three parallel `work:discoverer` invocations. Body text:

   ```markdown
   # Ticket Organizer

   Complete ticket creation workflow: discover context, check for duplicates, and write tickets. Runs in isolated context.

   ## Input

   - Request description (what the user wants to implement)
   - Target directory (`todo` or `icebox`)

   ## Output

   JSON per the Output Contract section of the preloaded **create-ticket** skill (success, duplicate, needs_decision, or needs_clarification).

   ## Procedure

   Follow the **Workflow** section of the preloaded **create-ticket** skill end-to-end. The skill carries the Lead Lens preloads (`standards:leading-*`) in scope and orchestrates the three parallel `work:discoverer` invocations.

   **CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion. Return JSON only.
   ```

6. **Thin `plugins/work/commands/ticket.md` to ~25 lines.** The command keeps three responsibilities the skill cannot perform (per the architecture policy, skills cannot invoke subagents or commands, and they cannot present AskUserQuestion): (a) pre-check the dependency probe, (b) worktree guard with `AskUserQuestion`, (c) invoke `work:ticket-organizer` via the Task tool, (d) relay `needs_decision` / `needs_clarification` results via `AskUserQuestion` and re-invoke the subagent with the answer, (e) commit the ticket file when not invoked during `/drive`. The Lead Lens note (line 12), the implementation-prevention CRITICAL (line 10), and the trip-branch compatibility note (line 42) are user-visible policy text and stay. Move the prose paragraphs that describe internal mechanics ("Trip branch compatibility: ticket-organizer detects these as non-main branches...") into a single short sentence; the detail belongs in the skill workflow if anywhere. After thinning the body is roughly: Notice → CRITICAL → Lead Lens note → Pre-check → Worktree Guard → Step 1 (Task invocation + response routing) → Step 2 (commit and present).

7. **Update CLAUDE.md "Plugin Dependencies" diagram.** Today the diagram shows `core (base)` and `standards (base)` with `work` depending on both. The text below the diagram says "work has soft references to standards". After this ticket, core also has a soft reference to standards (via `core:create-ticket` preloading `standards:leading-*`). Add a one-line note: "Core has soft references to work (context-aware routing in `/report` and `/ship`) and standards (Lead Lens preloads in `core:create-ticket`)." The diagram's directed arrows do not need to change — soft references are not depicted with arrows in the current diagram.

8. **Verification grep pass.** Run the following greps to confirm behavior preservation. Every match in the "must appear" lists below must be present at the new location:

   ```bash
   grep -rn 'work:discoverer\|subagent_type.*discoverer' plugins/core/skills/create-ticket/SKILL.md plugins/work/agents/ticket-organizer.md plugins/work/commands/ticket.md
   grep -rn 'AskUserQuestion' plugins/work/commands/ticket.md
   grep -rn 'check-worktrees\|check-deps\|branching/scripts/check\|branching/scripts/create\|gather/scripts/ticket-metadata' plugins/core/skills/create-ticket/SKILL.md plugins/work/commands/ticket.md
   grep -rn 'standards:leading-' plugins/work/agents/ticket-organizer.md plugins/core/skills/create-ticket/SKILL.md
   ```

   Required matches:

   - `work:discoverer` appears in `plugins/core/skills/create-ticket/SKILL.md` (Workflow step 2). Not in the thinned `ticket-organizer.md` (which now delegates to the skill).
   - `AskUserQuestion` appears in `plugins/work/commands/ticket.md` twice (worktree guard, response routing for needs_decision / needs_clarification). Not in the skill (skills cannot invoke AskUserQuestion).
   - `branching/scripts/check.sh` and `branching/scripts/create.sh` appear in `plugins/core/skills/create-ticket/SKILL.md` (Workflow step 1) with same-plugin path `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/`.
   - `check-deps/scripts/check.sh` appears in `plugins/work/commands/ticket.md` with cross-plugin path `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh` (command-level pre-check, not workflow content).
   - `check-worktrees.sh` and `list-all-worktrees.sh` appear in `plugins/work/commands/ticket.md` with cross-plugin paths (worktree guard, not skill content).
   - `gather/scripts/ticket-metadata.sh` appears in `plugins/core/skills/create-ticket/SKILL.md` (already does, unchanged).
   - `standards:leading-validity`, `standards:leading-accessibility`, `standards:leading-security`, `standards:leading-availability` appear in `plugins/core/skills/create-ticket/SKILL.md` frontmatter. Not in `plugins/work/agents/ticket-organizer.md` frontmatter.

9. **Behavior smoke test.** Invoke `/ticket` with a simple test description ("add a comment to the README explaining the marketplace structure"). Verify:
   - Pre-check runs (no failure if deps satisfied).
   - Worktree guard runs (Continue here / Switch to worktree if worktrees exist).
   - `work:ticket-organizer` is invoked once via Task tool.
   - Three `work:discoverer` Task invocations run in parallel from inside the agent (orchestrated by the skill workflow).
   - On `success`, a ticket file appears in `.workaholic/tickets/todo/` with the standard frontmatter and structure.
   - The commit step runs (or is skipped if invoked during `/drive`).
   - On `needs_decision` or `needs_clarification`, the command presents `AskUserQuestion` and re-invokes the agent with the answer.

## Patches

> **Note**: All three patches are speculative — they reflect the planned post-migration shape but specific line numbers and surrounding context should be verified before applying. The skill patch in particular adds two large new sections; the diff below shows the insertion points and high-level shape, not every line of the inserted content.

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -1,144 +1,21 @@
 ---
 name: ticket-organizer
 description: Discover context, check duplicates, and write implementation tickets. Runs in isolated context.
 tools: Read, Write, Edit, Glob, Grep, Bash, Task
 model: opus
 skills:
   - core:branching
   - core:create-ticket
   - core:gather
-  - standards:leading-validity
-  - standards:leading-accessibility
-  - standards:leading-security
-  - standards:leading-availability
 ---

 # Ticket Organizer

-Complete ticket creation workflow: discover context, check for duplicates, and write tickets.
+Complete ticket creation workflow: discover context, check for duplicates, and write tickets. Runs in isolated context.

 ## Input

-You will receive:
-
 - Request description (what the user wants to implement)
 - Target directory (`todo` or `icebox`)

-## Instructions
-
-### 1. Check Branch
-
-Follow preloaded **branching** skill to check current branch and create a new topic branch if on main/master.
-
-### 2. Parallel Discovery
-
-Invoke ALL THREE subagents concurrently using Task tool (single message with three parallel Task calls):
-
-- **discoverer (history)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: history" + full description. Receives JSON with summary, tickets list, match reasons, and moderation result (status/matches/recommendation).
-- **discoverer (source)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: source" + full description. Receives JSON with summary, files list, code flow.
-- **discoverer (policy)** (`subagent_type: "work:discoverer"`, `model: "opus"`): Pass "mode: policy" + full description. Receives JSON with summary, policies list, architecture patterns.
-
-Wait for all three to complete, then proceed with all JSON results.
-
-### 3. Handle Moderation Result
-... (lines 43-142 deleted; content migrates to create-ticket skill's Workflow and Output Contract sections) ...
+## Output
+
+JSON per the Output Contract section of the preloaded **create-ticket** skill (success, duplicate, needs_decision, or needs_clarification).
+
+## Procedure
+
+Follow the **Workflow** section of the preloaded **create-ticket** skill end-to-end. The skill carries the Lead Lens preloads (`standards:leading-*`) in scope and orchestrates the three parallel `work:discoverer` invocations.

 **CRITICAL**: Never implement code changes - only discover context and write tickets. Never commit. Never use AskUserQuestion. Return JSON only.
```

### `plugins/work/commands/ticket.md`

```diff
--- a/plugins/work/commands/ticket.md
+++ b/plugins/work/commands/ticket.md
@@ -1,69 +1,27 @@
 ---
 name: ticket
 description: Explore codebase and write implementation ticket for `$ARGUMENT`
 ---

 # Ticket

 **Notice:** When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.

 **CRITICAL:** NEVER implement code changes when this command is invoked - only create tickets. The actual implementation happens later via `/drive`.

 **Lead Lens**: Ticket scoping uses the `standards:leading-*` skills as policy lenses, mapped to the ticket's `layer` field. The `core:create-ticket` skill preloads them; the Lead Lens table in the skill documents the mapping.

 Thin alias for `work:ticket-organizer` subagent.

 ## Instructions

 ### Pre-check: Dependencies

 ```bash
 bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
 ```

 If `ok` is `false`, display the `message` to the user and stop.

 ### Step 0: Worktree Guard

 Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh`. If `has_worktrees` is `true`, present an `AskUserQuestion` with "Continue here" or "Switch to worktree" (list via `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-all-worktrees.sh`).

-### Step 1: Invoke Ticket Organizer
-
-Invoke ticket-organizer subagent via Task tool:
-
-```
-Task tool with subagent_type: "work:ticket-organizer", model: "opus"
-prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox based on argument>"
-```
-
-Handle the response:
-
-- `status: "success"` - If `branch_created` is present, confirm branch creation. Proceed to step 2.
-- `status: "duplicate"` - Inform user, show existing ticket path, done
-- `status: "needs_decision"` - Present options using `AskUserQuestion`, re-invoke with decision
-- `status: "needs_clarification"` - Present questions using `AskUserQuestion`, re-invoke with answers
-
-### Step 2: Commit and Present
-
-**Skip commit if invoked during `/drive`** - archive script handles it.
-
-Otherwise:
-- Stage ticket(s): `git add <paths>`
-- Commit: "Add ticket for <short-description>"
-- Present ticket location and summary
-- Tell user to run `/drive` to implement
+### Step 1: Invoke Ticket Organizer
+
+Invoke `work:ticket-organizer` via Task tool (`model: "opus"`, prompt: "Create ticket for: <$ARGUMENT>. Target: <todo|icebox>"). On `needs_decision` or `needs_clarification`, relay via `AskUserQuestion` and re-invoke with the answer. On `duplicate`, show the existing path and stop.
+
+### Step 2: Commit and Present
+
+Skip commit if invoked during `/drive` (archive script handles it). Otherwise stage and commit "Add ticket for <short-description>", present the ticket path, and tell the user to run `/drive`.
```

### `plugins/core/skills/create-ticket/SKILL.md`

```diff
--- a/plugins/core/skills/create-ticket/SKILL.md
+++ b/plugins/core/skills/create-ticket/SKILL.md
@@ -1,8 +1,12 @@
 ---
 name: create-ticket
 description: Create implementation tickets with proper format and conventions.
 skills:
   - gather
+  - standards:leading-validity
+  - standards:leading-accessibility
+  - standards:leading-security
+  - standards:leading-availability
 user-invocable: false
 ---

 # Create Ticket

 Guidelines for creating implementation tickets in `.workaholic/tickets/`.
@@ -86,6 +90,90 @@
 Use current timestamp: `date +%Y%m%d%H%M%S`

 Example: `20260114153042-add-dark-mode.md`

+## Workflow
+
+Followed by `work:ticket-organizer`. Skills cannot invoke subagents or AskUserQuestion directly; the steps below describe what the loading agent must do.
+
+### 1. Check Branch
+
+Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh`. If `on_main` is true, create a topic branch via `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh` and record the returned branch name as `branch_created` for the output JSON.
+
+### 2. Parallel Discovery
+
+Invoke `work:discoverer` three times in parallel (single message, three Task calls), `model: "opus"`, one per mode:
+
+- `history` — JSON with summary, tickets list, match reasons, and `moderation` (status/matches/recommendation).
+- `source` — JSON with summary, files list, code_flow, snippets.
+- `policy` — JSON with summary, policies list, architecture (principles, dependency_rules).
+
+Wait for all three. The `work:discoverer` slug is a soft cross-plugin reference; the skill itself does not declare a hard dependency on the work plugin.
+
+### 3. Handle Moderation Result
+
+- `moderation.status == "duplicate"` — return `status: "duplicate"` with existing ticket path.
+- `moderation.status == "needs_decision"` — return `status: "needs_decision"` with merge/split options.
+- `moderation.status == "clear"` — proceed to step 4.
+
+### 4. Evaluate Complexity
+
+- Split when: multiple independent features, unrelated layers, multiple commits needed.
+- Keep single when: tightly coupled, shared context, small enough for one commit.
+- If splitting: 2-4 discrete tickets, each independently implementable.
+
+### 5. Write Ticket(s)
+
+Follow the rest of this skill for format and content. Apply the Lead Lens table (below in this skill) to choose which leading skill's policies govern Implementation Steps, Considerations, and Patches. Populate sections from the three discovery JSONs:
+
+- history → Related History (summary + tickets list with paths and match reasons).
+- source → Key Files (files list) and Implementation Steps (code_flow).
+- source.snippets → Patches (generate unified diffs; mark speculative if interpretive; omit if no concrete diffs).
+- policy → Considerations (policies + architecture.principles + architecture.dependency_rules).
+
+If splitting: unique timestamps per ticket (+1 second between), first is foundation, populate `depends_on` only where there is a genuine ordering requirement (shared files, API contracts, schema changes), cross-reference in Considerations.
+
+### 6. Handle Ambiguity
+
+If ambiguous, return `status: "needs_clarification"` with a questions array.
+
+## Output Contract
+
+Return one of:
+
+```json
+{
+  "status": "success",
+  "branch_created": "work-20260202-181910",
+  "tickets": [
+    {"path": ".workaholic/tickets/todo/20260131-feature.md", "title": "Title", "summary": "One-line summary"}
+  ]
+}
+```
+
+`branch_created` is optional — only set if step 1 created a new branch.
+
+```json
+{"status": "duplicate", "existing_ticket": ".workaholic/tickets/todo/20260130-existing.md", "reason": "..."}
+```
+
+```json
+{
+  "status": "needs_decision",
+  "decision_type": "merge|split",
+  "details": "...",
+  "options": [{"label": "Option 1", "description": "..."}]
+}
+```
+
+```json
+{"status": "needs_clarification", "questions": ["Question 1?"]}
+```
+
+**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion (the command relays decisions/clarifications). Return JSON only.
+
 ## File Structure
```

## Considerations

- **Behavior preservation is non-negotiable.** Every script path, AskUserQuestion call, and subagent slug enumerated in Implementation Step 8 must appear post-migration. The verification grep is the contract. If any required match is missing after the patch lands, treat as a regression. (`plugins/work/agents/ticket-organizer.md`, `plugins/work/commands/ticket.md`, `plugins/core/skills/create-ticket/SKILL.md`)
- **Cross-plugin soft reference from core to work in skill body is intentional.** The Workflow section in `core:create-ticket` says "invoke `work:discoverer`". This is instructional text consumed by the loading agent (`work:ticket-organizer`), not a frontmatter dependency. The skill remains loadable when the work plugin is absent; the instruction simply has no caller in that scenario. This matches the soft-reference pattern documented in `CLAUDE.md` for `/report` and `/ship` in core soft-referencing `work:trip-protocol`. The core plugin's `dependencies` array stays `[]`. (`plugins/core/.claude-plugin/plugin.json`, `CLAUDE.md` "Plugin Dependencies")
- **`standards:leading-*` preloads relocate from agent to skill.** Per the user's directive and the documented "core CAN soft-depend on standards (skill preloads OK)" rule, the four leads move from `ticket-organizer.md` frontmatter to `create-ticket/SKILL.md` frontmatter. The Lead Lens table already lives in the skill, so the preload site now matches the documentation site. The `ticket-organizer` agent's frontmatter no longer carries the four entries; loading the agent still puts the leads in scope because the skill preload chains them. (`plugins/work/agents/ticket-organizer.md` frontmatter, `plugins/core/skills/create-ticket/SKILL.md` frontmatter, Lead Lens section)
- **Skills cannot invoke commands, subagents, or AskUserQuestion directly.** Per the Architecture Policy nesting rules (Skill → Skill only), the Workflow section in the skill describes what the loading agent must do; it does not itself spawn subagents. This is why `AskUserQuestion` calls stay in `ticket.md` (which is a command, allowed to invoke AskUserQuestion) and why the `work:discoverer` invocations are described in the skill but executed by the loading agent. (`CLAUDE.md` "Component Nesting Rules" table)
- **Tool list narrowing — keep all seven.** `ticket-organizer.md` declares `Read, Write, Edit, Glob, Grep, Bash, Task`. After thinning, the agent still: reads files (Read), creates and edits ticket files (Write, Edit), explores the codebase per the skill's "Exploring the Codebase" section (Glob, Grep), runs the branching and metadata bash scripts (Bash), and spawns three parallel `work:discoverer` invocations (Task). Every tool is still used. Do not narrow the list. (`plugins/work/agents/ticket-organizer.md` line 4)
- **Trip-branch compatibility text moves into the workflow.** The current `ticket.md` line 42 explains "ticket-organizer detects these as non-main branches and skips branch creation. Tickets go to `.workaholic/tickets/todo/` regardless of branch type. When running inside a trip worktree, tickets are created in the worktree's ticket directory." This is a property of the branch-check script (`branching/scripts/check.sh` only reports `on_main` for `main`/`master`, so any `trip/*` branch correctly returns `on_main: false`). The behavior is already implicit in Workflow step 1 of the skill; do not duplicate the prose, but keep the user-facing one-liner in the command for human readers. (`plugins/work/commands/ticket.md` line 42)
- **Lead Lens table stays in the skill.** The table is already in `create-ticket/SKILL.md` (lines 188-202). No edits to its content; only its frontmatter `skills:` list grows. The note "The `ticket-organizer` agent has these skills preloaded and applies them automatically" should change to "The `core:create-ticket` skill preloads these and applies them automatically; the agent that loads the skill inherits them in scope." (`plugins/core/skills/create-ticket/SKILL.md` Lead Lens section, line 202)
- **CLAUDE.md "Plugin Dependencies" diagram needs an updated text note.** After this ticket, core soft-references both work (existing) and standards (new, via `create-ticket` preloads). Add a one-line note below the diagram. The directional arrows in the diagram do not change. (`CLAUDE.md` "Plugin Dependencies" section)
- **No new dependencies in plugin.json files.** `plugins/core/.claude-plugin/plugin.json` `dependencies: []` stays. `plugins/work/.claude-plugin/plugin.json` `dependencies: ["core"]` stays. Soft references do not require declared dependencies. (`plugins/core/.claude-plugin/plugin.json`, `plugins/work/.claude-plugin/plugin.json`)
- **Hook reference unchanged.** `plugins/work/hooks/validate-ticket.sh` line 9 already points users at `plugins/core/skills/create-ticket/SKILL.md`. The skill stays at that path; the hook needs no edit. (`plugins/work/hooks/validate-ticket.sh` line 9)
- **Validity lens — Ours/Theirs Layer Segregation.** The migration reinforces the "thin orchestration / comprehensive knowledge" segregation that `standards:leading-validity` advocates: agents and commands are the orchestration layer (small, parameterized), skills are the knowledge layer (templates, workflows, guidelines, scripts). Ubiquitous Language is preserved — names (`ticket-organizer`, `create-ticket`, `work:discoverer`) are unchanged. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens — Vendor Neutrality.** No external dependencies introduced. The refactor is internal restructuring. `git mv` is not needed (no files move); only file contents change. History stays attached to the existing files. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **Accessibility lens does not apply directly.** This ticket touches Config layer only — no user-facing UI. The Lead Lens table notes Config → "whichever lead governs the affected behavior"; here the affected behavior is plugin orchestration, governed by validity (segregation) and availability (vendor neutrality). (`plugins/core/skills/create-ticket/SKILL.md` Lead Lens section)
- **Security lens does not apply directly.** No authentication, authorization, secrets, or input validation is touched. (`plugins/standards/skills/leading-security/SKILL.md`)
- **Effort estimate ~1h.** The change is mechanical: cut content from two files, paste-and-rewrite into one, adjust frontmatter, verify with grep. The risk is in the verification pass — the behavior-preservation contract has many small required matches.

## Final Report

(Filled by `/drive` after implementation.)
