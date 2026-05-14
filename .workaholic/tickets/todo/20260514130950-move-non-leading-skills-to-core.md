---
created_at: 2026-05-14T13:09:50+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Move non-leading standards skills to core

## Overview

Relocate every non-leading skill currently under `plugins/standards/skills/` into `plugins/core/skills/`. Ten skill directories move: `analyze-performance`, `analyze-policy`, `analyze-viewpoint`, `review-sections`, `validate-writer-output`, `write-changelog`, `write-overview`, `write-release-note`, `write-spec`, `write-terms`. Each is a reusable framework or content-structure guideline (templates, output schemas, gathering scripts) -- the same "knowledge layer reusable across codebases" identity that the recent `work -> core` skill move already established. After this ticket lands, `plugins/standards/skills/` contains only `leading-accessibility`, `leading-availability`, `leading-security`, and `leading-validity` -- the policy/standards skills the user wants to keep as the sole content of the standards plugin.

This ticket performs the directory moves and rewrites every `${CLAUDE_PLUGIN_ROOT}` path and `skills:` frontmatter entry affected by the move. The work plugin's manifest dependency `dependencies: ["core"]` is unchanged; cross-plugin references from work agents that currently target `${CLAUDE_PLUGIN_ROOT}/../standards/skills/<non-leading>/...` become `${CLAUDE_PLUGIN_ROOT}/../core/skills/<non-leading>/...`, and frontmatter `standards:<non-leading-skill>` entries become `core:<non-leading-skill>`.

Companion tickets:

- `20260514130949-move-standards-agents-to-work.md` -- relocates the agents that preload these skills. The two tickets are mechanically independent (either may land first) but share `CLAUDE.md` edits. If the agents ticket lands first, this ticket finds the agents already in `plugins/work/agents/` referencing `standards:<non-leading-skill>` (the interim form) and rewrites them to `core:<non-leading-skill>`. If this ticket lands first, the agents are still in `plugins/standards/agents/` referencing the unprefixed skill names (same-plugin); this ticket then rewrites every same-plugin reference to `core:<skill>` cross-plugin form. The "Implementation Steps" below explicitly handle both orderings.
- `20260514130951-move-standards-rules-to-work.md` -- independent of this ticket; touches a disjoint set of files.

## Key Files

### Skills to move (each entire directory, including `scripts/` subdirectory)

- `plugins/standards/skills/analyze-performance/` -> `plugins/core/skills/analyze-performance/` - decision-quality evaluation framework + `scripts/calculate.sh`
- `plugins/standards/skills/analyze-policy/` -> `plugins/core/skills/analyze-policy/` - policy analysis framework + `scripts/gather.sh`
- `plugins/standards/skills/analyze-viewpoint/` -> `plugins/core/skills/analyze-viewpoint/` - viewpoint analysis framework + `scripts/{gather.sh, read-overrides.sh}`
- `plugins/standards/skills/review-sections/` -> `plugins/core/skills/review-sections/` - story-section guidelines (no scripts)
- `plugins/standards/skills/validate-writer-output/` -> `plugins/core/skills/validate-writer-output/` - validation script wrapper + `scripts/validate.sh`
- `plugins/standards/skills/write-changelog/` -> `plugins/core/skills/write-changelog/` - changelog generation guidelines + `scripts/generate.sh`
- `plugins/standards/skills/write-overview/` -> `plugins/core/skills/write-overview/` - overview/journey content guidelines + `scripts/collect-commits.sh`
- `plugins/standards/skills/write-release-note/` -> `plugins/core/skills/write-release-note/` - release note structure (no scripts)
- `plugins/standards/skills/write-spec/` -> `plugins/core/skills/write-spec/` - spec document structure + `scripts/gather.sh`
- `plugins/standards/skills/write-terms/` -> `plugins/core/skills/write-terms/` - term document structure + `scripts/gather.sh`

### Skill-internal path rewrites (same-plugin references stay same-plugin)

Inside each moved skill, every `${CLAUDE_PLUGIN_ROOT}/skills/<self>/scripts/...` reference currently points at the skill's own scripts directory (same-plugin within standards). After the move it still points at the skill's own scripts directory (same-plugin within core). The `${CLAUDE_PLUGIN_ROOT}` placeholder expands to the *new* plugin root, so no rewrite is needed for any of these inline paths:

- `plugins/core/skills/analyze-performance/SKILL.md` line 14 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-performance/scripts/calculate.sh` (unchanged: same-plugin in both old and new home).
- `plugins/core/skills/analyze-policy/SKILL.md` line 18 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-policy/scripts/gather.sh` (unchanged).
- `plugins/core/skills/analyze-viewpoint/SKILL.md` lines 19, 29 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/{gather,read-overrides}.sh` (unchanged).
- `plugins/core/skills/validate-writer-output/SKILL.md` line 15 - `${CLAUDE_PLUGIN_ROOT}/skills/validate-writer-output/scripts/validate.sh` (unchanged).
- `plugins/core/skills/write-changelog/SKILL.md` line 17 - `${CLAUDE_PLUGIN_ROOT}/skills/write-changelog/scripts/generate.sh` (unchanged).
- `plugins/core/skills/write-overview/SKILL.md` line 17 - `${CLAUDE_PLUGIN_ROOT}/skills/write-overview/scripts/collect-commits.sh` (unchanged).
- `plugins/core/skills/write-spec/SKILL.md` line 18 - `${CLAUDE_PLUGIN_ROOT}/skills/write-spec/scripts/gather.sh` (unchanged).
- `plugins/core/skills/write-terms/SKILL.md` line 17 - `${CLAUDE_PLUGIN_ROOT}/skills/write-terms/scripts/gather.sh` (unchanged).

### Skill-internal frontmatter rewrites

- `plugins/core/skills/analyze-viewpoint/SKILL.md` lines 5-7 (frontmatter `skills:`) - currently lists `- write-spec` unprefixed (same-plugin in standards). After the move, `write-spec` is in the same plugin (core), so the unprefixed form remains correct. **No change.**

No other moved SKILL.md files preload sibling non-leading skills.

### Caller updates: work-agent frontmatter `skills:` entries

If the companion agents-move ticket has already landed, the moved agents now live in `plugins/work/agents/` and currently reference the about-to-move skills via `standards:<non-leading-skill>` (the interim cross-plugin form set by the agents ticket). Every such entry must be rewritten to `core:<non-leading-skill>`.

If the agents ticket has not yet landed, the agents still live in `plugins/standards/agents/` and currently reference these skills unprefixed (same-plugin). After this ticket, those references become cross-plugin from standards into core; the unprefixed form must become `core:<skill>`.

In either ordering, the set of files and target entries is the same:

- `<agents-home>/changelog-writer.md` line 6 (frontmatter) - `write-changelog` (or `standards:write-changelog`) -> `core:write-changelog`
- `<agents-home>/lead.md` lines 10-12 (frontmatter) - `analyze-policy`, `analyze-viewpoint`, `write-spec` (or `standards:`-prefixed forms) -> `core:analyze-policy`, `core:analyze-viewpoint`, `core:write-spec`. The four `leading-*` entries on lines 6-9 are **not** rewritten (those skills stay in standards; the entry remains `leading-*` unprefixed if `lead.md` is still in standards, or `standards:leading-*` if it has been moved to work).
- `<agents-home>/model-analyst.md` lines 6-7 (frontmatter) - `analyze-viewpoint`, `write-spec` -> `core:analyze-viewpoint`, `core:write-spec`
- `<agents-home>/overview-writer.md` line 7 (frontmatter) - `write-overview` -> `core:write-overview`
- `<agents-home>/performance-analyst.md` line 7 (frontmatter) - `analyze-performance` -> `core:analyze-performance`. The `- core:gather-git-context` entry on line 6 is unchanged.
- `<agents-home>/release-note-writer.md` line 6 (frontmatter) - `write-release-note` -> `core:write-release-note`
- `<agents-home>/section-reviewer.md` line 7 (frontmatter) - `review-sections` -> `core:review-sections`
- `<agents-home>/terms-writer.md` line 6 (frontmatter) - `write-terms` -> `core:write-terms`

Where `<agents-home>` is `plugins/standards/agents/` if the companion ticket has not yet landed, or `plugins/work/agents/` if it has.

### Caller updates: work-agent inline `${CLAUDE_PLUGIN_ROOT}` paths

Same conditional on the companion ticket. The set of paths is:

- `<agents-home>/model-analyst.md` lines 26, 31 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/...` (if still in standards) or `${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-viewpoint/scripts/...` (if moved to work) -> `${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/...` (if still in standards, becomes same-plugin in core after this ticket -- but the file is in standards, so it must become `${CLAUDE_PLUGIN_ROOT}/../core/...`) or `${CLAUDE_PLUGIN_ROOT}/../core/skills/analyze-viewpoint/scripts/...` (if file is in work). The simpler restatement: after this ticket, every reference to a non-leading skill's scripts from any caller outside `core/skills/` becomes `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/scripts/...`. From an agent in `plugins/standards/agents/`, the prefix is `../core/`. From an agent in `plugins/work/agents/`, the prefix is also `../core/` (work depends on core, declared).
- `<agents-home>/overview-writer.md` line 25 - same pattern with `write-overview`
- `<agents-home>/performance-analyst.md` line 18 - same pattern with `analyze-performance`
- `<agents-home>/terms-writer.md` line 23 - same pattern with `write-terms`

`changelog-writer.md`, `lead.md`, `release-note-writer.md`, `section-reviewer.md` do not contain inline script paths.

### `plugins/work/commands/` and other work content

No work command file references any of the moved skills directly. `plugins/work/agents/story-writer.md` references the moved-agent names (`overview-writer`, `section-reviewer`, `release-note-writer`) via `Task` invocations, not skills; those references are handled by the companion agents-move ticket. No further edits are required outside the agents.

### `plugins/core/` cross-references

After the move, every `plugins/core/skills/` entry can reference the moved skills as same-plugin. The current `plugins/core/skills/` content does not preload or invoke any of the moved skills (verified by `grep`), so no rewrites are required inside core itself.

### `plugins/work/.claude-plugin/plugin.json`

- `dependencies: ["core"]` is unchanged. The moved skills are preloaded by work-side agents (once the companion ticket relocates them) via the declared `core` dependency. Until that ticket lands, the moved skills are preloaded by agents in `plugins/standards/agents/` via cross-plugin reference into core -- this is a soft reference (skill preload) and requires no `standards -> core` dependency declaration.

### `plugins/standards/.claude-plugin/plugin.json`

- `dependencies: []` is unchanged. After both companion tickets land, standards has no callers and no callees -- it is a pure policy library that work soft-references.

### Documentation updates

- `CLAUDE.md` lines 20-24 - the standards block's `skills/` listing currently reads `skills/ # leading-*, analyze-*, write-*`. After this ticket it becomes `skills/ # leading-*`. The core block's `skills/` listing on line 20 currently reads `skills/ # branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, ship, system-safety, trip-protocol`. After this ticket it gains the ten moved skill basenames -- preferred form: keep the list alphabetized.
- `.workaholic/specs/data.md` line 471 - references `plugins/standards/skills/leading-*/SKILL.md`. Unchanged (those skills stay in standards). No other spec file references the moved skill paths.

## Related History

This is the third in a recent series of plugin-boundary redraws that reuse the same path-rewrite playbook. The two immediately preceding tickets did exactly this kind of move in the opposite direction (work -> core) and back (core -> work), establishing the conventions for `${CLAUDE_PLUGIN_ROOT}` flips, frontmatter prefixes, and `CLAUDE.md` reconciliation. The earlier work-plugin merger and the core/standards reorganizations provide deeper precedent.

Past tickets that touched similar areas:

- [20260514121259-move-work-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514121259-move-work-skills-to-core.md) - Most relevant precedent: moved six skills from work to core, rewriting every same-plugin `${CLAUDE_PLUGIN_ROOT}` path into `../core/` form and flipping every `skills:` frontmatter prefix. This ticket is the same operation in a different direction (standards -> core).
- [20260514121300-move-report-ship-commands-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514121300-move-report-ship-commands-to-work.md) - Companion to the precedent above; documents the two-ticket reconciliation pattern this ticket reuses (each ticket owns its slice of the shared `CLAUDE.md` block).
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - Comprehensive cross-reference audit pattern used by the verification grep step below.
- [20260128-220712-feat-extract-skills-from-standards-plugin.md or similar] -- earlier standards refactors that split policy from process; if present in archive they document the original placement rationale of these skills. (The exact match may be elsewhere in `archive/feat-*`; the discoverer agent surfaced the work/core moves as the most directly comparable.)

## Implementation Steps

1. **Determine companion ticket ordering.** Check whether `20260514130949-move-standards-agents-to-work.md` has already landed:
   - `[ -d plugins/standards/agents ] && [ -n "$(ls plugins/standards/agents 2>/dev/null)" ]` -> agents ticket NOT landed (agents still in standards).
   - Otherwise -> agents ticket HAS landed (agents now in work).
   The result determines `<agents-home>` for steps 3 and 4 below.

2. **Move skill directories.** For each of the ten skill names listed in "Skills to move", run `git mv plugins/standards/skills/<name>/ plugins/core/skills/<name>/`. Verify executable bits on shell scripts survive the move (`ls -l plugins/core/skills/*/scripts/*.sh`). Confirm `plugins/standards/skills/` now contains only `leading-accessibility`, `leading-availability`, `leading-security`, `leading-validity`.

3. **Rewrite caller frontmatter `skills:` entries.** In each of the eight agent files (`changelog-writer.md`, `lead.md`, `model-analyst.md`, `overview-writer.md`, `performance-analyst.md`, `release-note-writer.md`, `section-reviewer.md`, `terms-writer.md`) at `<agents-home>`, change every preload entry that names a moved skill to the `core:<skill>` form. See the explicit list in "Caller updates: work-agent frontmatter `skills:` entries" above. For `lead.md`, leave the four `leading-*` entries alone (they stay in standards).

4. **Rewrite caller inline `${CLAUDE_PLUGIN_ROOT}` paths.** In `model-analyst.md`, `overview-writer.md`, `performance-analyst.md`, and `terms-writer.md` at `<agents-home>`, change every inline path that names a moved skill to use `${CLAUDE_PLUGIN_ROOT}/../core/skills/<skill>/scripts/...`. From either `plugins/standards/agents/` or `plugins/work/agents/`, the relative form `../core/` is correct (standards and work both reach core via the same relative path because plugins are siblings under `plugins/`).

5. **Update `CLAUDE.md` Project Structure.** Edit the block at lines 18-30:
   - Core's `skills/` line gains ten entries: `analyze-performance`, `analyze-policy`, `analyze-viewpoint`, `review-sections`, `validate-writer-output`, `write-changelog`, `write-overview`, `write-release-note`, `write-spec`, `write-terms`. Final form (alphabetized): `skills/ # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms`. (If the listing grows too long for one line, the entry may be elided to `skills/ # branching, leading-*, write-*, ... (full list in plugin)` or similar; the verbose form above is preferred for grep discoverability.)
   - Standards' `skills/` line becomes `skills/ # leading-*` (only the four lead policy skills remain).
   - The standards `agents/` line is owned by the companion agents-move ticket. If that ticket has already landed, the line is already gone; if not, leave it alone.

6. **Verification pass.**
   - `ls plugins/standards/skills/` must show exactly `leading-accessibility leading-availability leading-security leading-validity` and nothing else.
   - `grep -rn '\${CLAUDE_PLUGIN_ROOT}/\(\.\./\)\?standards/skills/\(analyze-\|write-\|review-\|validate-\)' plugins/` must return zero matches (every reference to a moved skill must point at core).
   - `grep -rn '^  - standards:\(analyze-\|write-\|review-\|validate-\)' plugins/` (frontmatter only) must return zero matches.
   - `grep -rn '^  - \(analyze-\|write-\|review-\|validate-\)' plugins/` (unprefixed frontmatter entries naming a moved skill) must return zero matches outside `plugins/core/`. (Inside `plugins/core/`, only same-plugin references remain valid; specifically `plugins/core/skills/analyze-viewpoint/SKILL.md` retains `- write-spec`.)
   - Invoke `/report` end-to-end on a `work-*` branch to confirm the `overview-writer`, `section-reviewer`, and `release-note-writer` agents successfully load their respective preloaded skills from core. Invoke a standalone test of `model-analyst`, `performance-analyst`, or `terms-writer` if a clean test path is available.

## Considerations

- **Two valid orderings with the companion agents ticket.** This ticket and `20260514130949-move-standards-agents-to-work.md` are mechanically independent: either can land first. Step 1 above explicitly handles both orderings by locating the agents' current home before applying frontmatter and inline-path rewrites. The set of edits is identical in either ordering; only the file paths change. (`plugins/standards/agents/`, `plugins/work/agents/`)
- **Shared `CLAUDE.md` block.** Both companion tickets edit the Project Structure block in `CLAUDE.md`. The recent two-ticket precedent shows the reconciliation pattern: each ticket owns disjoint lines (this ticket owns the `skills/` listings under `standards/` and `core/`; the agents-move ticket owns the `agents/` listing under `standards/`). Whichever ticket lands second merges its line edits onto the first ticket's tree without conflict. (`CLAUDE.md` lines 18-30)
- **Soft references stay soft.** No `plugin.json` change is required. Work calling into core for these skills uses the already-declared `dependencies: ["core"]`. Work calling into standards for `leading-*` remains a soft reference (no manifest entry). The dependency diagram in `CLAUDE.md` is unchanged. (`plugins/work/.claude-plugin/plugin.json`, `plugins/standards/.claude-plugin/plugin.json`, `CLAUDE.md` lines 45-52)
- **`scripts/` subdirectories travel with their skills.** Each moved skill's `scripts/` directory is part of the skill and must move with it (verified by `ls` in step 2). The `${CLAUDE_PLUGIN_ROOT}/skills/<self>/scripts/...` self-references inside each SKILL.md remain same-plugin after the move (the placeholder expands to core's plugin root in the new home), so no rewrite is needed for those. (`plugins/standards/skills/analyze-performance/scripts/`, etc.)
- **No skill renames; ubiquitous-language preserved.** Skill basenames stay stable. Prose mentions like "follow the preloaded **write-overview** skill" in agent body text need no change. Only frontmatter `skills:` lists and `${CLAUDE_PLUGIN_ROOT}` script paths are affected. (`standards:leading-validity` Ubiquitous Language policy)
- **Validity lens (Ours/Theirs Layer Segregation).** Pulling reusable knowledge into core and leaving standards as a pure policy plugin sharpens the "core = library, standards = policy lens, work = application" segregation. After this ticket, standards has no code dependencies on any other plugin and zero internal cross-references between skills (other than `analyze-viewpoint` preloading `write-spec`, which moves with it to core). This is the cleanest possible identity for the standards plugin: a self-contained collection of `leading-*` policies that other plugins consume via soft reference. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens (Vendor Neutrality, IaC).** No external dependencies are introduced; the move is purely internal restructuring. `git mv` preserves history. No CI/CD pipeline changes are required because plugin packaging is not affected by skill-directory layout within a plugin. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **Cross-reference companion tickets.** The companion `20260514130949-move-standards-agents-to-work.md` and `20260514130951-move-standards-rules-to-work.md` complete the standards-reduction described in the user's request. After all three land, `plugins/standards/` contains only `.claude-plugin/` and `skills/leading-*`, matching the stated goal that standards should hold "only the actual standards and policies".

## Patches

> **Note**: The patches below assume the companion agents-move ticket has NOT yet landed (so the agent files are still in `plugins/standards/agents/` and reference these skills unprefixed). If the agents ticket lands first, the patches apply to `plugins/work/agents/<file>` and the "before" form is `standards:<skill>` instead of unprefixed. Implementers should check the current state before applying.

### `plugins/standards/agents/model-analyst.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/model-analyst.md
+++ b/plugins/standards/agents/model-analyst.md
@@ -3,8 +3,8 @@
 description: Analyze repository from model viewpoint and generate spec documentation.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - analyze-viewpoint
-  - write-spec
+  - core:analyze-viewpoint
+  - core:write-spec
 ---

 # Model Analyst
@@ -23,12 +23,12 @@

 1. **Gather Context**: Run:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/gather.sh model main
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/analyze-viewpoint/scripts/gather.sh model main
    ```

 2. **Check Overrides**: Run:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/read-overrides.sh
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/analyze-viewpoint/scripts/read-overrides.sh
    ```
    If overrides exist for this viewpoint, incorporate them into your analysis.
```

### `plugins/standards/agents/overview-writer.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/overview-writer.md
+++ b/plugins/standards/agents/overview-writer.md
@@ -4,7 +4,7 @@
 tools: Read, Bash, Glob, Grep
 model: haiku
 skills:
-  - write-overview
+  - core:write-overview
 ---

 # Overview Writer
@@ -22,7 +22,7 @@

 1. **Collect Commits**: Run the write-overview skill script:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/write-overview/scripts/collect-commits.sh <base-branch>
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/write-overview/scripts/collect-commits.sh <base-branch>
    ```
```

### `plugins/standards/agents/performance-analyst.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/performance-analyst.md
+++ b/plugins/standards/agents/performance-analyst.md
@@ -3,7 +3,7 @@
 description: Evaluate decision-making quality across five viewpoints
 skills:
   - core:gather-git-context
-  - analyze-performance
+  - core:analyze-performance
 ---

 # Performance Analyst
@@ -15,7 +15,7 @@
 1. **Gather context** using the preloaded gather-git-context skill
 2. **Calculate metrics** using the preloaded analyze-performance skill:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-performance/scripts/calculate.sh <base_branch>
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/analyze-performance/scripts/calculate.sh <base_branch>
    ```
```

### `plugins/standards/agents/terms-writer.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/terms-writer.md
+++ b/plugins/standards/agents/terms-writer.md
@@ -3,7 +3,7 @@
 description: Update .workaholic/terms/ documentation to maintain consistent term definitions. Use after completing implementation work.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - write-terms
+  - core:write-terms
 ---

 # Terms Writer
@@ -19,7 +19,7 @@

 1. **Gather Context**: Use the "Gather Context" section of the preloaded write-terms skill:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/write-terms/scripts/gather.sh [base-branch]
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/write-terms/scripts/gather.sh [base-branch]
    ```
    Read archived tickets if they exist, otherwise use diff output.
```

### `plugins/standards/agents/lead.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/lead.md
+++ b/plugins/standards/agents/lead.md
@@ -7,9 +7,9 @@
   - leading-availability
   - leading-security
   - leading-accessibility
-  - analyze-policy
-  - analyze-viewpoint
-  - write-spec
+  - core:analyze-policy
+  - core:analyze-viewpoint
+  - core:write-spec
 ---
```

### `plugins/standards/agents/changelog-writer.md` / `release-note-writer.md` / `section-reviewer.md` (pre-companion form)

```diff
--- a/plugins/standards/agents/changelog-writer.md
+++ b/plugins/standards/agents/changelog-writer.md
@@ -3,7 +3,7 @@
 description: Update root CHANGELOG.md from archived tickets. Groups entries by category and links to commits and tickets.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - write-changelog
+  - core:write-changelog
 ---
```

```diff
--- a/plugins/standards/agents/release-note-writer.md
+++ b/plugins/standards/agents/release-note-writer.md
@@ -3,7 +3,7 @@
 description: Generate release notes from branch story for GitHub Releases.
 tools: Read, Write, Glob, Grep
 skills:
-  - write-release-note
+  - core:write-release-note
 ---
```

```diff
--- a/plugins/standards/agents/section-reviewer.md
+++ b/plugins/standards/agents/section-reviewer.md
@@ -4,7 +4,7 @@
 tools: Read, Glob, Grep
 model: haiku
 skills:
-  - review-sections
+  - core:review-sections
 ---
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,11 +17,10 @@
 plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    skills/              # branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, ship, system-safety, trip-protocol
+    skills/              # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    agents/              # lead, writers, analysts
-    skills/              # leading-*, analyze-*, write-*
+    skills/              # leading-*
   work/                  # Work plugin: drive + trip workflows (depends on: core)
     .claude-plugin/      # Plugin configuration
     agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
```

> **Note**: The `agents/` line removal is owned by the companion `20260514130949-move-standards-agents-to-work.md` ticket. This patch shows the post-both-tickets final state for clarity; whichever ticket lands second reconciles to the same line set.
