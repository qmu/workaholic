---
created_at: 2026-05-14T15:47:49+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Thin `ship` and `discover` umbrellas: move procedural content from work-side files into core skills

## Overview

Refactor two component umbrellas so that the work-side agent/command file is a thin alias and the core skill carries all instructional content. After this ticket lands:

- `/ship` (the command at `plugins/work/commands/ship.md`) is reduced to ~10-20 lines (frontmatter + a few lines describing entry). Every workflow step, every `bash <script>` invocation, every `AskUserQuestion` prompt currently in the command body is absorbed into `plugins/core/skills/ship/SKILL.md`.
- The `discoverer` agent (`plugins/work/agents/discoverer.md`) is verified to already be thin at 30 lines (frontmatter + I/O contract + mode routing table) and is touched only if a trivial reduction is found; the bulk of the discoverer umbrella's body has always lived in `plugins/core/skills/discover/SKILL.md` (358 lines).

This is the first and smallest of five planned thinning tickets. It bundles two umbrellas because each has only half the usual pair: `ship` has only a command (no agent); `discoverer` has only an agent (no command). Bundling keeps the ticket at a meaningful size and exercises the thinning pattern on the lowest-risk scope.

Behavior is preserved exactly. Every script path, every AskUserQuestion option text, every conditional branch, and every step ordering in `/ship` survives — only its lexical home changes. The `discoverer` agent's mode-based dispatch (history/source/policy) is unchanged.

### Why bundle these two

- **Both umbrellas have a thin half already.** `discoverer` is 30 lines today; its skill is 358 lines. Migration cost is near-zero. `ship/SKILL.md` is 100 lines and `ship.md` is 79 lines — the only umbrella in this batch where the command is nearly as long as its skill. The two together produce a single coherent thinning commit at the right size (~0.5h).
- **No `standards:leading-*` preload migration is actually required.** Verification grep against both work-side files returned zero `leading-*` frontmatter entries. The architectural rule "core can soft-depend on standards (skill preloads OK)" is documented in this ticket for the four remaining umbrellas, but the two in scope here have nothing to migrate. The body prose of `discover/SKILL.md` already cites `standards:leading-{validity,availability,security,accessibility}` (line 304) as a discovery target — that is a content reference, not a preload, and stays as-is.

## Key Files

### Files to modify

- `plugins/work/commands/ship.md` (79 lines) — reduce to a thin wrapper. After this ticket, the body holds only a one-paragraph entry pointer (~5-10 lines) plus the existing `## Instructions` heading directing the reader to follow the preloaded `core:ship` skill in order. The four `### Step N` blocks (Workspace Guard, Ticket Guard, Detect Context, Route by Context) and their script invocations move into `plugins/core/skills/ship/SKILL.md`.
- `plugins/core/skills/ship/SKILL.md` (100 lines) — absorb the procedural body from `ship.md`. Add new sections covering the four workflow steps. Keep existing sections (Cloud.md Convention, Shell Scripts catalog) intact and re-anchor them under a new top-level structure that begins with the workflow steps.
- `plugins/work/agents/discoverer.md` (30 lines) — verify already-thin status. Audit confirms it is at target. The `## Mode Routing` table at lines 19-26 is the I/O contract; everything else is frontmatter. No edit is required unless a stray instruction is found during re-read. Listed as in-scope so the verification is recorded as part of this ticket.
- `plugins/core/skills/discover/SKILL.md` (358 lines) — unchanged. Already holds the comprehensive knowledge layer.

### Files verified not affected

- `plugins/work/.claude-plugin/plugin.json` — declares `dependencies: ["core"]`; that already covers every cross-plugin path used in the thinned `ship.md`. No manifest edit is required.
- `plugins/core/.claude-plugin/plugin.json` — `dependencies: []` stays. Absorbing instructional content into `core:ship` and `core:discover` adds no outbound dependency from core. The body-prose reference to `standards:leading-*` in `discover/SKILL.md` line 304 is a citation, not a preload, and remains a soft reference.
- `CLAUDE.md` — the Project Structure block already shows `core/skills/` including `ship` and `discover`; the work skills inventory has no `ship` or `discover` entries (they live in core). The Architecture Policy block (Thin commands and subagents, comprehensive skills, lines 56-65) explicitly supports this thinning. No edit is required.
- All `${CLAUDE_PLUGIN_ROOT}` script paths in scope already use the correct prefix. Inside `ship.md`, every script call uses `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/scripts/...` (cross-plugin from work into core). When those calls move into `ship/SKILL.md` (which lives in core), they must be rewritten to same-plugin form `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/...`. The Implementation Steps below enumerate every rewrite.

### Content map — `/ship` command body to `core:ship` skill body

The command body has four numbered steps plus three context routes. The mapping is one-to-one:

| Command source (line) | Skill destination (new section) | Content |
| --------------------- | ------------------------------- | ------- |
| `ship.md` lines 18-30 (Step 0: Workspace Guard) | New section `## 3. Workspace Guard` in `ship/SKILL.md` | `check-workspace.sh` call + AskUserQuestion options "Ignore and proceed" / "Stop" |
| `ship.md` lines 32-44 (Step 0.5: Ticket Guard) | New section `## 4. Ticket Guard` in `ship/SKILL.md` | `check-todo.sh` call + AskUserQuestion options "Move all to icebox" / "Stop" + commit message text |
| `ship.md` lines 46-52 (Step 1: Detect Context) | New section `## 5. Detect Context` in `ship/SKILL.md` | `detect-context.sh` call + JSON parse rule |
| `ship.md` lines 54-65 (Work Context route) | New section `## 6. Route by Context` (Work subsection) in `ship/SKILL.md` | Pre-check, Merge PR, Sync gitignored files, Clean up worktree, Deploy, Verify, Summarize — 7 numbered substeps |
| `ship.md` lines 66-75 (Worktree Context route) | `## 6. Route by Context` (Worktree subsection) | `list-worktrees.sh` + filter + AskUserQuestion variants |
| `ship.md` lines 77-79 (Unknown Context route) | `## 6. Route by Context` (Unknown subsection) | AskUserQuestion with "Drive"/"Trip" options |

After the move, the existing `ship/SKILL.md` sections renumber:
- Current `## 1. Cloud.md Convention` -> `## 1. Cloud.md Convention` (unchanged position)
- Current `## 2. Shell Scripts` (script catalog) -> `## 2. Shell Scripts` (unchanged position; remains a reference catalog the workflow steps point into)
- New `## 3. Workspace Guard`, `## 4. Ticket Guard`, `## 5. Detect Context`, `## 6. Route by Context` (added below the existing two sections)

This ordering keeps the existing skill content stable as a reference (Cloud.md convention + script catalog) at the top, and adds the workflow procedure beneath. An alternate ordering — workflow first, reference catalog second — is also acceptable; the implementer may choose. The patches in this ticket use the "reference first, procedure second" ordering for minimal diff impact on the existing sections.

### Path rewrites when content moves work -> core

Every `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/scripts/...` reference in `ship.md` becomes `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/...` once the line is inside `ship/SKILL.md`. The set:

- `ship.md` line 21 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh` -> `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh` (cross-plugin within core's own perspective: branching is a sibling skill, also in core, so use `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh`). The `../` form is wrong from inside core.
- `ship.md` line 35 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/check-todo.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh` (same-plugin from `ship/SKILL.md`'s vantage)
- `ship.md` line 49 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh`
- `ship.md` line 58 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/pre-check.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh`
- `ship.md` line 59 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/merge-pr.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh`
- `ship.md` line 60 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/find-gitignored-files.sh` and `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/sync-gitignored-files.sh` -> drop the `../core/` prefix in both
- `ship.md` line 61 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh`
- `ship.md` line 62 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/find-cloud-md.sh` — already present in `ship/SKILL.md` line 19 (no duplicate needed; the workflow step can cross-reference the existing entry in section 1-1 or restate the call with the same-plugin prefix)
- `ship.md` line 70 — `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`

Every other inline-path occurrence (e.g., the existing `find-cloud-md.sh` call in `ship/SKILL.md` lines 19, 63) already uses the same-plugin form and is unchanged.

### Discoverer audit (no edits expected)

A re-read of `plugins/work/agents/discoverer.md` confirms:

- Lines 1-8 frontmatter: `name`, `description`, `tools`, `model`, `skills: [core:discover]` — already in target form (no `standards:leading-*` entries; no procedural body).
- Lines 10-13: single-paragraph statement of purpose pointing at the preloaded skill.
- Lines 14-30: `## Input`, `## Mode Routing` (3-row table), `## Output` — collectively the I/O contract.

This matches the "thin agent" target exactly. The ticket records "no edits required" as the verified outcome rather than performing a no-op rewrite.

## Related History

Recent tickets in the same campaign reorganized which plugin owns which component but did not yet thin the work-side wrappers. This ticket starts the next phase: turning agents and commands into aliases of their skills so that Codex-spec-compatible callers see the work plugin as a thin orchestration layer over the core skill library.

Past tickets that touched similar areas:

- [20260514150430-delete-dead-agents-and-orphan-skills.md](.workaholic/tickets/archive/work-20260417-092936/20260514150430-delete-dead-agents-and-orphan-skills.md) - Removed five dead agents and six orphan skills from work and core; established the verification grep pattern that this ticket reuses to confirm no dangling references after the content move.
- [20260514130950-move-non-leading-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514130950-move-non-leading-skills-to-core.md) - Moved ten non-leading skills from standards to core; documented the same `${CLAUDE_PLUGIN_ROOT}` rewrite playbook (same-plugin form `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/...` vs cross-plugin form `${CLAUDE_PLUGIN_ROOT}/../<plugin>/skills/<skill>/...`) that this ticket applies in microcosm to the lines that move from `ship.md` into `ship/SKILL.md`.
- [20260514121300-move-report-ship-commands-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514121300-move-report-ship-commands-to-work.md) - Relocated `/report` and `/ship` from core to work; this ticket inherits the resulting `ship.md` (currently the longest user-facing version of the command) and thins it. The path rewrites that ticket installed are the ones this ticket reverses (cross-plugin -> same-plugin) when each line moves into the core skill.
- [20260514150414-merge-write-overview-into-report.md](.workaholic/tickets/archive/work-20260417-092936/20260514150414-merge-write-overview-into-report.md) - Same-batch precedent for collapsing a wrapper into its skill; documents the size targets and the "preserve every script call exactly" rule.
- [20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) - Established the `standards:leading-*` preload pattern on work-side agents/commands; this ticket confirms (via verification grep) that no such preloads currently exist on the two umbrellas in scope, so no migration to core is required for this ticket.

## Implementation Steps

1. **Verify discoverer is already thin.** Re-read `plugins/work/agents/discoverer.md` end-to-end. Confirm:
   - Frontmatter contains exactly the keys `name`, `description`, `tools`, `model`, `skills`.
   - Body contains exactly: one-paragraph purpose, `## Input`, `## Mode Routing` (3-row table), `## Output`.
   - No `### Step N` blocks, no `bash` invocations, no `AskUserQuestion` prompts, no procedural content of any kind.
   - No `standards:leading-*` entries in `skills:`.
   If all confirmed, record "no edit required" and skip to step 2. If any procedural content is found, move it into the matching section of `plugins/core/skills/discover/SKILL.md` (likely the "Discover History|Source|Policy" subsection that matches the mode), then rewrite the agent line to reference the new skill section.

2. **Catalog the four workflow steps in `ship.md`.** Copy the contents of each `### Step N` block (Workspace Guard, Ticket Guard, Detect Context, Route by Context) into a working buffer, including every `bash` invocation, every AskUserQuestion option string, and every conditional branch. Preserve exact wording — the user-facing prompts ("Ignore and proceed", "Stop", "Move all to icebox", "Copy all to main worktree", "Skip and erase", "Drive", "Trip") must round-trip identically.

3. **Rewrite `${CLAUDE_PLUGIN_ROOT}` paths for in-core context.** For every line in the working buffer that names a script under `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/scripts/...`, drop the `../core/` prefix. The result is `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/...` — the same-plugin form correct for a SKILL.md inside the core plugin. See the explicit list in "Path rewrites when content moves work -> core" above (8 distinct paths across 8 lines of `ship.md`).

4. **Append the rewritten workflow steps to `ship/SKILL.md`.** Add four new top-level sections in order: `## 3. Workspace Guard`, `## 4. Ticket Guard`, `## 5. Detect Context`, `## 6. Route by Context`. The first three each contain one `bash` block and an AskUserQuestion description. Section 6 contains three subsections (Work, Worktree, Unknown) covering all routing paths. Keep the existing sections `## 1. Cloud.md Convention` and `## 2. Shell Scripts` untouched and ordered above the new sections.

5. **Reduce `ship.md` to a thin wrapper.** After the move, replace the body of `plugins/work/commands/ship.md` (everything after the closing frontmatter `---` on line 8) with a short alias body. Recommended content (~5-10 lines):
   ```markdown
   # Ship

   **Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` — whether "run /ship", "do /ship", "ship it", or similar — they likely want this command.

   Context-aware ship workflow. Follow the preloaded **core:ship** skill end-to-end: Workspace Guard, Ticket Guard, Detect Context, then Route by Context (work / worktree / unknown).
   ```
   The frontmatter (lines 1-8) stays exactly as it is today — `name`, `description`, and `skills: [core:trip-protocol, core:ship, core:branching]` are correct under the new design.

6. **Verification pass.**
   - `wc -l plugins/work/commands/ship.md` should report under 25 lines (frontmatter + thin body).
   - `wc -l plugins/work/agents/discoverer.md` should remain 30 (no expected change).
   - `grep -n 'bash \${CLAUDE_PLUGIN_ROOT}' plugins/work/commands/ship.md` must return zero matches (no script invocations remain in the command).
   - `grep -n 'AskUserQuestion' plugins/work/commands/ship.md` must return zero matches.
   - `grep -n 'AskUserQuestion' plugins/core/skills/ship/SKILL.md` must return matches covering all five distinct prompt sites (Workspace Guard, Ticket Guard, Sync gitignored files, Worktree-context selection, Unknown-context Drive/Trip).
   - Every script path enumerated in the "Path rewrites" table above must appear in `ship/SKILL.md` under its rewritten same-plugin form, and must NOT appear under its cross-plugin form anywhere in `plugins/work/commands/ship.md` or `plugins/core/skills/ship/SKILL.md`.
   - End-to-end behavior check: from a worktree on a `work-*` branch with a merged PR, invoke `/ship`. Confirm the four guards/steps run in their existing order, that user-facing prompts read identically to the pre-refactor versions, and that the workflow reaches Summarize with the same status fields. Repeat the check from a clean main with worktrees present (Worktree Context route) to verify the `list-worktrees.sh` filter behavior is preserved.

## Patches

> **Note**: These patches assume the implementer keeps the "reference first, procedure second" section ordering in `ship/SKILL.md`. The alternate ordering (procedure first) is acceptable; in that case, the section numbering shifts but the line content is identical.

### `plugins/work/commands/ship.md` — reduce to thin wrapper

```diff
--- a/plugins/work/commands/ship.md
+++ b/plugins/work/commands/ship.md
@@ -7,72 +7,7 @@ skills:
   - core:branching
 ---

 # Ship

-**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.
-
-Context-aware ship command that auto-detects whether you are in a drive or trip workflow, merges the PR, deploys, and verifies. For trip workflows, it additionally cleans up the worktree.
-
-## Instructions
-
-### Step 0: Workspace Guard
-
-```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
-```
-
-Parse the JSON output. If `clean` is `true`, proceed silently to Step 1.
-
-If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
-- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
-- **"Stop"** - Halt the command so you can handle the changes first.
-
-If the user selects "Stop", end the command immediately.
-
-### Step 0.5: Ticket Guard
-
-```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/check-todo.sh
-```
-
-(... 50 more lines of step bodies and routing logic removed; see ship/SKILL.md ...)
+**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` — whether "run /ship", "do /ship", "ship it", or similar — they likely want this command.
+
+Context-aware ship workflow. Follow the preloaded **core:ship** skill end-to-end: Workspace Guard, Ticket Guard, Detect Context, then Route by Context (work / worktree / unknown).
```

> **Note**: The patch elides the middle of the deletion for readability — the full delete spans `ship.md` lines 12-79. The implementer should remove every line from line 12 through line 79 inclusive and replace with the three replacement lines shown above.

### `plugins/core/skills/ship/SKILL.md` — append the four workflow sections

```diff
--- a/plugins/core/skills/ship/SKILL.md
+++ b/plugins/core/skills/ship/SKILL.md
@@ -98,3 +98,76 @@ Copies selected gitignored files from the worktree to the main repo root, creati
 ```json
 {"synced": true, "count": 2, "files": [".env", ".local.md"]}
 ```
+
+## 3. Workspace Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-workspace.sh
+```
+
+Parse the JSON output. If `clean` is `true`, proceed silently to the Ticket Guard.
+
+If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
+- **"Ignore and proceed"** — Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
+- **"Stop"** — Halt the command so you can handle the changes first.
+
+If the user selects "Stop", end the workflow immediately.
+
+## 4. Ticket Guard
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
+```
+
+Parse the JSON output. If `clean` is `true`, proceed silently to Detect Context.
+
+If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in `.workaholic/tickets/todo/`:" followed by the ticket filenames. Then ask via AskUserQuestion with selectable options:
+- **"Move all to icebox"** — Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to Detect Context.
+- **"Stop"** — Halt the command so you can handle tickets first (run `/drive`, manually reorganize, etc.).
+
+If the user selects "Stop", end the workflow immediately.
+
+## 5. Detect Context
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/detect-context.sh
+```
+
+Parse the JSON output. Route to the appropriate workflow based on `context`.
+
+## 6. Route by Context
+
+### Work Context (`context: "work"`)
+
+1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Clean up worktree.
+2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
+3. **Sync gitignored files** (if worktree exists): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-gitignored-files.sh "<worktree-path>"`. If `has_changes` is `true`, display the file list and ask via AskUserQuestion with options: **"Copy all to main worktree"**, **"Skip and erase"**. If "Copy all", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'` with all file paths. If `has_changes` is `false`, proceed silently. If no worktree exists, skip this step.
+4. **Clean up worktree** (if applicable): Check if `.worktrees/<branch>/` exists. If yes, run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/cleanup-worktree.sh "<branch>"` and report what was cleaned up. If no worktree exists, skip this step.
+5. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
+6. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
+7. **Summarize**: PR merge status (number, URL), gitignored file sync status, worktree cleanup status, deployment status, verification results.
+
+### Worktree Context (`context: "worktree"`)
+
+Not on a work branch, but worktrees exist.
+
+1. Run `bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh`
+2. Filter to worktrees where `has_pr` is `true` (branches with PRs ready to ship)
+3. If no shippable worktrees found: inform the user "No worktrees with open PRs found. Run `/report` first." and stop.
+4. If exactly one shippable worktree: ask the user "Found '<name>' with PR #<number>. Ship?" using AskUserQuestion. If confirmed, use it.
+5. If multiple shippable worktrees: list them with PR numbers and ask the user which one to ship using AskUserQuestion.
+6. Once selected, follow Work Context steps 1-6.
+
+### Unknown Context (`context: "unknown"`)
+
+Ask the user: "Could not determine development context from branch '<branch>'. Are you working on a drive or trip?" using AskUserQuestion with options "Drive" and "Trip". Route accordingly.
```

> **Note**: The patch above keeps two `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/...` references inside `ship/SKILL.md` (lines for `check-workspace.sh`, `cleanup-worktree.sh`, `detect-context.sh`, `list-worktrees.sh`). These are wrong from inside the core plugin — they should be `${CLAUDE_PLUGIN_ROOT}/skills/branching/...` (same-plugin). The patch reproduces the form found in the source `ship.md` to show the literal copy; the implementer **must** apply the same-plugin rewrite enumerated in step 3 before committing. Marking this caveat explicitly because it is the single mechanical detail most likely to slip during the move. After rewrite, no `${CLAUDE_PLUGIN_ROOT}/../core/` substring should remain anywhere in `ship/SKILL.md`.

### `plugins/work/agents/discoverer.md` — no change expected

No patch. Audit only (see step 1).

## Considerations

- **No `standards:leading-*` preloads exist on either umbrella's work-side file.** The verification grep against `plugins/work/agents/discoverer.md` and `plugins/work/commands/ship.md` returned zero matches for `leading-` or `standards:`. The architectural rule "core can soft-depend on standards (skill preloads OK)" therefore needs no application in this ticket. The four remaining umbrella tickets in this batch will likely need to apply it; this ticket documents the rule's existence and confirms it does not bind here. (`CLAUDE.md` Plugin Dependencies block lines 47-54)
- **`discover/SKILL.md` body prose cites `standards:leading-*` at line 304 as a discovery target.** This is a content citation (instructing the discoverer to inspect the four leading-* skills as part of policy discovery), not a frontmatter preload. It stays as-is. Body-prose citations do not count as soft references under the dependency rules; only frontmatter `skills:` entries and `${CLAUDE_PLUGIN_ROOT}/../<plugin>/` script paths do. (`plugins/core/skills/discover/SKILL.md` line 304)
- **Path-direction flip when content moves work -> core.** Every script path embedded in the lines that travel from `ship.md` into `ship/SKILL.md` must lose its `../core/` prefix because the new home is itself inside core. There are 8 such paths; the explicit list is in the Key Files section. Failing to flip them produces paths like `${CLAUDE_PLUGIN_ROOT}/../core/skills/ship/scripts/check-todo.sh` invoked from inside core, which Claude Code's plugin loader will resolve to a sibling-of-core path that does not exist. This is the only kind of bug the refactor can introduce, and the verification grep in step 6 catches it. (`plugins/core/skills/ship/SKILL.md`)
- **AskUserQuestion text is part of the public interface.** Users have built habits around the exact option strings: "Ignore and proceed", "Stop", "Move all to icebox", "Copy all to main worktree", "Skip and erase", "Drive", "Trip", plus the "Found '<name>' with PR #<number>. Ship?" template. Every string moves verbatim; any substitution (even reflowing whitespace) is a behavior change disallowed by the ticket scope. (`plugins/work/commands/ship.md` lines 27-29, 41-43, 60, 73-74, 79)
- **The `discoverer` agent's `tools:` field already names what it needs.** Line 4 declares `tools: Bash, Read, Glob, Grep`. The thinning target permits narrowing tools to only what the agent itself invokes in its body. In the post-refactor agent body (which contains no inline shell commands or file reads), the agent itself invokes none of these — it merely returns JSON. However, every tool that the preloaded `core:discover` skill needs (Bash for `search.sh`, Read/Glob/Grep for source mode) must be in the parent agent's tool list because skills run in the agent's context. The current four-tool set is exactly correct and should not be narrowed. Document this finding in the audit log; do not edit the line. (`plugins/work/agents/discoverer.md` line 4)
- **Commands have no `tools:` field by design.** `ship.md`'s frontmatter declares `name`, `description`, `skills` and nothing else. Commands run in the main Claude context with access to every tool the user has authorized; the `skills:` preload list is the only orchestration declaration. The thin-command target does not introduce a `tools:` field. (`CLAUDE.md` Design Principle, lines 56-65)
- **Validity lens (Type-Driven Design, Ours/Theirs Layer Segregation).** The thinning sharpens the layer split: the work plugin becomes purely the "ours" side (project-specific orchestration aliases), and the core plugin becomes purely the "theirs" side (reusable instructional content + scripts). The interface between them — the `skills:` frontmatter list — is the type-driven contract. By construction, after this ticket every step in `/ship`'s behavior is named by a section in `core:ship`; if a future PR removes or renames a section in the skill, the wrapper's reference becomes a dangling pointer that fails at load time rather than at runtime. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Validity lens (Ubiquitous Language).** Section names in the migrated `ship/SKILL.md` should match the terminology already used in the command: "Workspace Guard", "Ticket Guard", "Detect Context", "Route by Context". The patches above preserve this exactly. Renaming any of the four during the move would create a divergence between the user-visible terminology (used in commit messages, PR descriptions, and changelogs) and the skill body. (`plugins/standards/skills/leading-validity/SKILL.md` Ubiquitous Language policy)
- **Availability lens (CI/CD Automation First, Observable by Design).** No CI/CD or telemetry change. The refactor is structural; runtime behavior is unchanged. Use a single `git mv`-free commit because no file is renamed — content is rewritten in place across two files. The commit message should be something like "Thin /ship command into core:ship; verify discoverer already thin" so the changelog clearly attributes the size delta. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **Cross-reference the four sibling tickets.** This is the smallest of five. Each sibling thins a different umbrella using the same pattern (work-side body absorbed into core skill; `standards:leading-*` preloads — if any — migrated per rule #2). The siblings can land in any order; their content scopes are disjoint. This ticket establishes the pattern and the verification recipe; the others reuse both. (Cross-references to be added when the four sibling tickets are created.)
- **No security or accessibility lens applies.** No auth, secrets, input validation, or user-facing UX surface is touched. `leading-security` and `leading-accessibility` policies are inactive for this ticket. (`plugins/standards/skills/leading-security/SKILL.md`, `plugins/standards/skills/leading-accessibility/SKILL.md`)
