---
created_at: 2026-05-14T15:46:50+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: d4f2c9d
category: Changed
depends_on:
---

# Thin the work-side drive umbrella into the core:drive skill

## Overview

Move procedural content from `plugins/work/agents/drive-navigator.md` (128 lines) and `plugins/work/commands/drive.md` (151 lines) into `plugins/core/skills/drive/SKILL.md` (404 lines). After the migration the agent and command become thin wrappers (~10-20 lines each) consisting of frontmatter selectors plus a short I/O contract pointing at the skill, while the skill carries the full workflow, navigator instructions, approval flow, final report, archive, and frontmatter-update knowledge.

This is a **refactor only**: every step that ran before still runs, every prompt to the user still appears, every script invocation still happens with the same arguments, and the order of operations is unchanged. The migration also moves `standards:leading-*` preloads off the thin command onto `core:drive` itself (allowed under the dependency rules — core may *soft*-depend on standards via skill preloads) so the leading skills load transitively from a single source of truth.

Total surface today: 683 lines across three files. Target after refactor: ~430-470 lines, almost entirely in the skill.

## Key Files

- `plugins/work/agents/drive-navigator.md` (128 lines) - Agent to thin to ~15-20 lines. Frontmatter selectors and a short I/O contract remain; all procedural sections (Icebox Mode, Normal Mode, List and Analyze Tickets, Determine Priority Order, Present Prioritized List, Confirm Order with User, Output schema) migrate into a new "Navigator" section in `core:drive`.
- `plugins/work/commands/drive.md` (151 lines) - Command to thin to ~15-20 lines. Frontmatter selectors remain; all phases (Pre-check, Phase 0 Worktree Guard, Phase 1 Navigate Tickets, Phase 2 Implement Tickets, Phase 3 Re-check and Continue, Phase 4 Completion, Critical Rules) migrate into a new "Command Workflow" section in `core:drive`. The current `skills:` list (`core:drive`, `core:system-safety`, `standards:leading-*`) is reduced to `core:drive` only; the rest become preloads on the skill.
- `plugins/core/skills/drive/SKILL.md` (404 lines) - Receives migrated content. Add three new top-level sections at the head: "Command Workflow" (from `commands/drive.md`), "Navigator" (from `agents/drive-navigator.md`), and adjust the skill's own frontmatter to preload `core:system-safety`, `standards:leading-validity`, `standards:leading-accessibility`, `standards:leading-security`, `standards:leading-availability` (the latter four are soft references — allowed by the dependency policy in `CLAUDE.md` lines 49-53). Existing sections (Workflow, Approval, Final Report, Archive, Update Frontmatter) remain in place verbatim.
- `CLAUDE.md` (no edits anticipated) - Verify that the rewritten files still satisfy the "Thin commands and subagents, comprehensive skills" principle (lines 55-61) and the "Shell Script Principle" (lines 74-96). No structural rules change.
- `plugins/core/.claude-plugin/plugin.json` - No edits. `core` already has no declared dependencies; soft preloads of `standards:leading-*` from a core skill remain soft per the policy in `CLAUDE.md` lines 49-53.
- `plugins/work/.claude-plugin/plugin.json` - No edits. Work continues to depend on core.
- `plugins/core/skills/drive/scripts/archive.sh` - No edits. Referenced from the thin command via `${CLAUDE_PLUGIN_ROOT}/../core/skills/drive/scripts/archive.sh`; the reference moves into the skill body and the path resolves identically because the skill itself lives under `plugins/core/`.
- `plugins/core/skills/drive/scripts/update.sh` - No edits. Already referenced from the skill.

## Related History

This refactor follows a well-established pattern in the repository: thin orchestration files in favor of a single comprehensive skill, especially after the manager tier was eliminated and leading skills were wired into work flows.

Past tickets that touched similar areas:

- [20260128004252-thin-ticket-command.md](.workaholic/tickets/archive/feat-20260128-001720/20260128004252-thin-ticket-command.md) - Established the thin-command pattern this ticket applies to `/drive`.
- [20260202125814-ticket-command-alias-refactor.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125814-ticket-command-alias-refactor.md) - Earlier command-as-alias refactor; same direction as this ticket.
- [20260202125850-remove-driver-subagent.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125850-remove-driver-subagent.md) - Removed the driver subagent; this ticket continues the simplification by thinning the remaining drive-navigator subagent.
- [20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) - Added `standards:leading-*` preloads to `/drive`; this ticket relocates those preloads onto the core skill.
- [20260514150430-delete-dead-agents-and-orphan-skills.md](.workaholic/tickets/archive/work-20260417-092936/20260514150430-delete-dead-agents-and-orphan-skills.md) - Recent surface cleanup; same housekeeping direction.

## Implementation Steps

### Step 1 — Inventory and map content (read-only)

Read all three files end to end and produce a content map. Each row records: source file, section heading, lines, destination in `core:drive`.

Expected mapping (verify against the current files before editing):

| Source | Section | Lines | Destination in `core:drive` |
| ------ | ------- | ----- | --------------------------- |
| `commands/drive.md` | Pre-check: Dependencies | 21-27 | New top-level section "Command Workflow" → "Pre-check: Dependencies" |
| `commands/drive.md` | Phase 0: Worktree Guard | 29-45 | "Command Workflow" → "Phase 0: Worktree Guard" |
| `commands/drive.md` | Phase 1: Navigate Tickets | 47-64 | "Command Workflow" → "Phase 1: Navigate Tickets" |
| `commands/drive.md` | Phase 2: Implement Tickets (with all sub-steps) | 66-107 | "Command Workflow" → "Phase 2: Implement Tickets" |
| `commands/drive.md` | Phase 3: Re-check and Continue | 109-125 | "Command Workflow" → "Phase 3: Re-check and Continue" |
| `commands/drive.md` | Phase 4: Completion | 127-136 | "Command Workflow" → "Phase 4: Completion" |
| `commands/drive.md` | Critical Rules | 138-151 | "Command Workflow" → "Critical Rules" |
| `agents/drive-navigator.md` | Icebox Mode | 19-32 | New top-level section "Navigator" → "Icebox Mode" |
| `agents/drive-navigator.md` | Normal Mode (steps 1-4) | 34-108 | "Navigator" → "Normal Mode" |
| `agents/drive-navigator.md` | Output | 110-128 | "Navigator" → "Output" |

The skill's existing sections (Workflow, Approval, Final Report, Archive, Update Frontmatter) stay in place verbatim. Insert the two new top-level sections at the top of the skill body, **above** the existing `## Workflow` heading, in this order: `## Command Workflow`, `## Navigator`. This preserves the natural reading order: command-level orchestration first, then subagent details, then per-ticket workflow.

### Step 2 — Adjust skill script paths to in-plugin form

Every script invocation moved from `commands/drive.md` currently uses `${CLAUDE_PLUGIN_ROOT}/../core/skills/...` (cross-plugin from `work`). Once the content lives inside `plugins/core/skills/drive/SKILL.md`, the prefix must change to `${CLAUDE_PLUGIN_ROOT}/skills/...` (same-plugin from `core`). The argument lists do not change.

Specifically:

| Current path in `commands/drive.md` | After move into `core:drive` |
| ----------------------------------- | ---------------------------- |
| `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh` | `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` |
| `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh` | `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh` |
| `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-all-worktrees.sh` | `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh` |
| `${CLAUDE_PLUGIN_ROOT}/../core/skills/drive/scripts/archive.sh` | `${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh` |

These resolutions are runtime-equivalent because `${CLAUDE_PLUGIN_ROOT}` expands to the host plugin's installed directory; the new prefix points to the same on-disk path. The existing `${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh` and `${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh` references already inside the skill remain untouched.

### Step 3 — Move `standards:leading-*` preloads onto `core:drive`

Today `plugins/work/commands/drive.md` declares:

```yaml
skills:
  - core:drive
  - core:system-safety
  - standards:leading-validity
  - standards:leading-accessibility
  - standards:leading-security
  - standards:leading-availability
```

After the move, the **command** declares only `core:drive`. The **skill** itself declares the rest:

```yaml
# plugins/core/skills/drive/SKILL.md frontmatter
skills:
  - commit
  - system-safety
  - standards:leading-validity
  - standards:leading-accessibility
  - standards:leading-security
  - standards:leading-availability
```

Runtime equivalence: Claude Code merges a skill's declared `skills:` into the caller's scope when the skill is preloaded. Because the thin command preloads `core:drive`, and `core:drive` preloads the leading skills, the leading skills end up in the command's runtime scope just as before. This is identical to how `core:drive` already pulls in `commit` today (the command never named `commit` directly).

**Dependency-policy check**: `CLAUDE.md` lines 49-53 state that `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must target *declared* dependencies, but skill preloads are explicitly listed as *soft* references that do not require a declaration. The existing `core` plugin declares no dependencies. Adding `standards:leading-*` as soft preloads from a core skill remains within policy. No `plugin.json` changes are required.

### Step 4 — Narrow the agent tool list

`drive-navigator.md` currently declares `tools: Bash, Glob, Read`. After thinning, audit each:

- **Bash**: Still required. The migrated Navigator section (in the skill) invokes `ls -1 .workaholic/tickets/...` and `mv ... && git add ...` from the agent's tool context. The skill runs *inside* the calling agent's tool grant, so the agent must still have `Bash`.
- **Read**: Still required. The Navigator reads ticket frontmatter to extract `type`, `layer`, `depends_on`.
- **Glob**: Optional. The Navigator uses `ls -1 ... *.md` rather than `Glob`. If a careful audit of the migrated text confirms no `Glob` usage remains, drop it. If unsure, retain it — narrowing the tool list is a nice-to-have, not the goal of this ticket.

Decision rule: **prefer keeping the current tool list intact** unless removal is demonstrably safe. The goal is behavior preservation; tool narrowing is secondary.

### Step 5 — Rewrite the agent to a thin wrapper

Replace `plugins/work/agents/drive-navigator.md` body with a short I/O contract that points at the skill's Navigator section. Frontmatter retains `name`, `description`, `tools`, and adds `skills: [core:drive]` so the Navigator section is preloaded. Target shape:

```markdown
---
name: drive-navigator
description: Navigate and prioritize tickets for /drive command. Handles listing, analysis, and user confirmation.
tools: Bash, Glob, Read
skills:
  - core:drive
---

# Drive Navigator

Navigate tickets for the `/drive` command. This subagent runs the **Navigator** section of the `core:drive` skill — follow it end to end.

## Input

You receive:

- `mode`: Either `"normal"` or `"icebox"`

## Output

Return the JSON object specified in the skill's Navigator → Output section.
```

Body length target: ~15-20 lines including frontmatter.

### Step 6 — Rewrite the command to a thin wrapper

Replace `plugins/work/commands/drive.md` body with a short entry point pointing at the skill's Command Workflow section. Frontmatter retains `name`, `description`, and `skills: [core:drive]` only. The `Notice:` line about user intent recognition stays (it is a Claude-Code-level instruction that needs to live on the command surface; it cannot be inferred from a preloaded skill).

Target shape:

```markdown
---
name: drive
description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
skills:
  - core:drive
---

# Drive

**Notice:** When user input contains `/drive` — whether "run /drive", "do /drive", "start /drive", or similar — they likely want this command.

This command runs the `core:drive` skill. Follow the **Command Workflow** section end to end.
```

Body length target: ~15-20 lines.

### Step 7 — Update the skill's frontmatter and add a brief overview

Update `plugins/core/skills/drive/SKILL.md` frontmatter to declare the new preloads (see Step 3). Add a one-line introduction noting that the skill covers both the command workflow and the navigator subagent in addition to the per-ticket workflow. The existing line "Step-by-step workflow for implementing a single ticket during `/drive`" stays — it correctly scopes the original Workflow section.

### Step 8 — Verification

Run the grep/diff verification plan in the Considerations section to confirm logical equivalence. Specifically, every unique string in the table below must appear *somewhere* in the union of the three files after the refactor, and the totals must match the pre-refactor counts.

## Patches

> **Note**: The patches below are exemplary — they show the shape of the rewrite. The full insertion patch for the skill (~280 lines of moved content) is omitted because verbatim copy is mechanical; verify diff-equivalence in the verification step rather than reviewing the insertion patch line by line.

### `plugins/work/agents/drive-navigator.md`

```diff
--- a/plugins/work/agents/drive-navigator.md
+++ b/plugins/work/agents/drive-navigator.md
@@ -1,128 +1,18 @@
 ---
 name: drive-navigator
 description: Navigate and prioritize tickets for /drive command. Handles listing, analysis, and user confirmation.
 tools: Bash, Glob, Read
+skills:
+  - core:drive
 ---

 # Drive Navigator

-Navigate tickets for the `/drive` command. Lists, analyzes, prioritizes, and confirms execution order with user.
+Navigate tickets for the `/drive` command. This subagent runs the **Navigator** section of the `core:drive` skill — follow it end to end.

 ## Input

-You will receive:
+You receive:

 - `mode`: Either "normal" or "icebox"

-## Instructions
-
-### Icebox Mode (mode = "icebox")
-
-1. List tickets in `.workaholic/tickets/icebox/`:
-   ...
-### Normal Mode (mode = "normal")
-...
 ## Output

-Return a JSON object:
-
-```json
-{
-  "status": "ready",
-  "tickets": [ ... ]
-}
-```
-...
+Return the JSON object specified in the skill's Navigator → Output section.
```

### `plugins/work/commands/drive.md`

```diff
--- a/plugins/work/commands/drive.md
+++ b/plugins/work/commands/drive.md
@@ -1,151 +1,15 @@
 ---
 name: drive
 description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
 skills:
   - core:drive
-  - core:system-safety
-  - standards:leading-validity
-  - standards:leading-accessibility
-  - standards:leading-security
-  - standards:leading-availability
 ---

 # Drive

 **Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

-Implement tickets from `.workaholic/tickets/todo/` using intelligent prioritization, committing and archiving each one before moving to the next.
-
-## Instructions
-
-### Pre-check: Dependencies
-...
-### Phase 4: Completion
-...
-## Critical Rules
-...
+This command runs the `core:drive` skill. Follow the **Command Workflow** section end to end.
```

### `plugins/core/skills/drive/SKILL.md`

```diff
--- a/plugins/core/skills/drive/SKILL.md
+++ b/plugins/core/skills/drive/SKILL.md
@@ -1,11 +1,17 @@
 ---
 name: drive
 description: Implementation workflow, approval flow, final report, archive, and frontmatter update for drive sessions.
 skills:
   - commit
+  - system-safety
+  - standards:leading-validity
+  - standards:leading-accessibility
+  - standards:leading-security
+  - standards:leading-availability
 allowed-tools: Bash
 user-invocable: false
 ---

 # Drive

-Complete drive session skill covering implementation, approval, reporting, archiving, and frontmatter updates.
+Complete drive session skill covering the `/drive` command workflow, the drive-navigator subagent, per-ticket implementation, approval, reporting, archiving, and frontmatter updates.
+
+## Command Workflow
+
+<MIGRATED FROM plugins/work/commands/drive.md — see Implementation Step 1 for the section mapping. All script paths rewritten per Step 2: ${CLAUDE_PLUGIN_ROOT}/../core/skills/... → ${CLAUDE_PLUGIN_ROOT}/skills/...>
+
+## Navigator
+
+<MIGRATED FROM plugins/work/agents/drive-navigator.md — see Implementation Step 1 for the section mapping.>

 ## Workflow
```

## Considerations

### Behavior preservation is the acceptance criterion

This is a refactor. The implementer must verify that the union of `(thin command + thin agent + skill_after)` carries the same instructions as `(command_before + agent_before + skill_before)`. The following unique strings MUST appear *somewhere* in the post-refactor file set (run `grep -F` across all three files and confirm at least one hit each):

| Category | String to verify |
| -------- | ---------------- |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` (was `.../core/skills/...`) |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh` |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh` |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh` |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh` |
| Script call | `${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh` |
| AskUserQuestion site | `"Continue here"` / `"Switch to worktree"` |
| AskUserQuestion site | `"Approve"` / `"Approve and stop"` / `"Abandon"` |
| AskUserQuestion site | `"Move to icebox"` / `"Skip for now"` / `"Abort drive"` |
| AskUserQuestion site | `"Work on icebox"` / `"Stop"` |
| AskUserQuestion site | `"Proceed"` / `"Pick one"` / `"Original order"` |
| Task invocation | `subagent_type: "work:drive-navigator"` |
| Phase/section heading | `Phase 0: Worktree Guard`, `Phase 1: Navigate Tickets`, `Phase 2: Implement Tickets`, `Phase 3: Re-check and Continue`, `Phase 4: Completion` |
| Critical rule | `NEVER autonomously move tickets to icebox` |
| Critical rule | `NEVER manually archive tickets` |
| Notice | `When user input contains \`/drive\`` |
| Effort values | `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h` |
| Final Report header | `## Final Report` |
| Discussion header | `## Discussion` |
| Failure header | `## Failure Analysis` |

If any of these strings is missing post-refactor, the migration lost content. Fix before committing.

### Dependency-rule compliance (`CLAUDE.md` lines 42-72)

The skill preloads `standards:leading-*`. Core declares no dependency on standards in `plugin.json`. This is permitted because skill preloads are *soft* references per the policy at lines 49-53. Cross-plugin shell script references (`${CLAUDE_PLUGIN_ROOT}/../<name>/...`) would require a declared dependency — but the moved content uses only `${CLAUDE_PLUGIN_ROOT}/skills/...` paths (in-plugin), so no hard cross-plugin reference is introduced (`plugins/core/skills/drive/SKILL.md` lines 24, 34, 39, 87 once rewritten).

### Shell Script Principle (`CLAUDE.md` lines 74-117)

The moved content contains short inline `ls -1` and `mv ... && git add ...` invocations from the navigator. The migration preserves them verbatim. They predate the Shell Script Principle and may eventually want extraction into navigator scripts, but extraction is out of scope for this ticket. Note this as future technical debt (affects `plugins/core/skills/drive/SKILL.md` Navigator section, formerly `plugins/work/agents/drive-navigator.md` lines 22-24, 28-31, 41-42, 47-49).

### Leading skill applicability (Lead Lens)

Layer is `Config`. The relevant lead is whichever lead governs the affected behavior — here the drive workflow surfaces relate to availability (operational continuity of the drive session) and validity (logical comprehensiveness of the prioritization rules). Apply `standards:leading-availability` in particular: preserving every script invocation and every approval prompt is exactly the kind of operational continuity guarantee that lead asks for (`plugins/standards/skills/leading-availability/SKILL.md`).

### Runtime equivalence assertion (must be tested manually)

After the refactor, run one end-to-end `/drive` session against a real test ticket to confirm: dependency pre-check fires, worktree guard prompts identically, navigator presents the same prioritized list with the same option strings, approval dialog appears with proper title/overview, archive script runs with the expected arguments, todo re-check fires at the end. If any prompt is missing or any script fails to run, the migration is incomplete (`plugins/work/commands/drive.md` end-to-end behavior).

### Reviewer note

The skill insertion patch will be large (~280 lines of moved content). Reviewers should diff `commands/drive.md` BEFORE against the new "Command Workflow" section in the skill, and `agents/drive-navigator.md` BEFORE against the new "Navigator" section, line by line. The only intentional textual changes are the four script path prefixes listed in Step 2 — everything else copies verbatim (`plugins/core/skills/drive/SKILL.md`).

## Final Report

Development completed as planned. Final line counts: drive-navigator 21, /drive 12, drive/SKILL.md 666. All verification grep checks passed.

### Discovered Insights

- **Insight**: This was the largest single-umbrella thin in the batch (~280 lines of work-side content migrated into the skill). The umbrella-skill pattern scales to 600+ lines as long as the structure has clear top-level sections.
  **Context**: Size limit is reader navigation, not file length. As long as each top-level section is independently meaningful and reachable via `Follow ## <Section>`, growth is sustainable.
- **Insight**: Intra-skill section references ("Follow the **Workflow** section below") replace cross-file references ("Follow the preloaded **drive** skill (Approval section)") and are clearer because they're scoped to a single document.
  **Context**: When a thin caller references a single skill, prefer "Follow the **<Section>** section" — self-contained — over "Follow the preloaded **<skill>** skill (<Section>)" which assumes preload context.
