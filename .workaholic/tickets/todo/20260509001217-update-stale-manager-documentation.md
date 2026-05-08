---
created_at: 2026-05-09T00:12:17+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260509001215-eliminate-manager-tier.md, 20260509001216-wire-leads-into-work-flows.md]
---

# Update Stale Documentation After Manager Tier Removal

## Update Stale Documentation After Manager Tier Removal

## Overview

After the manager tier and `/scan` command are removed and the work plugin's flows are wired directly to the leading skills, several documentation files still describe the old structure. This ticket sweeps them to match the new reality:

- `CLAUDE.md` lists `manage-*` skills under `plugins/standards/skills/` and references `/scan` in the commands table.
- `plugins/core/README.md` references `/scan`.
- `.workaholic/specs/{application,component,data,infrastructure,ux}.md` describe the manager tier, the two-phase scan execution model, manager-to-leader output flow, and per-leader inventories that include lead names that have been consolidated.

The `.workaholic/stories/`, `.workaholic/release-notes/`, and `CHANGELOG.md` directories are historical and remain untouched. Specs are hand-maintained reference docs (per the foundation ticket — they no longer have an automated owner) and are updated alongside structural changes via `/ticket`, which is what this ticket exemplifies.

## Key Files

- `CLAUDE.md` - Project Structure section, Commands table, Plugin Dependencies note
- `plugins/core/README.md` - Commands table
- `.workaholic/specs/application.md` - Drivin orchestration model, two-phase execution, manager/leader inventories, manager output flow, scan flow diagram
- `.workaholic/specs/component.md` - Plugin/agent/skill inventory counts and lists; manager-tier sections
- `.workaholic/specs/data.md` - Manager output data flow, constraint files
- `.workaholic/specs/infrastructure.md` - Scan command in environment/runtime descriptions
- `.workaholic/specs/ux.md` - User-facing command list, scan UX
- `.workaholic/specs/README.md` - Verify it does not list managed-only documents

## Related History

The specs are stale because the manager tier they describe is being removed in the foundation ticket of this series. The ux/component/data/application/infrastructure documents were written when the manager tier was the centerpiece of the orchestration story.

Past tickets that touched similar areas:

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created the manager tier these docs describe
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170402-wire-leaders-to-manager-outputs.md) - Created the two-phase execution model these docs describe
- [20260123005256-japanese-translation-policy.md] (or similar) - Established the bilingual spec convention; remember to update the Japanese counterparts (`*_ja.md`) consistently

## Implementation Steps

1. **Verify the foundation and wiring tickets have merged.**

   This ticket depends on both `20260509001215-eliminate-manager-tier.md` and `20260509001216-wire-leads-into-work-flows.md`. Confirm the manager tier is gone and the work-plugin wiring is in place before sweeping documentation.

2. **Update `CLAUDE.md`.**

   - In the Project Structure block, remove `manage-*` from the standards `skills/` line:

     before: `skills/              # lead-*, manage-*, analyze-*, write-*`
     after:  `skills/              # leading-*, leaders-principle, analyze-*, write-*`

   - Also update the standards `agents/` line to drop "managers":

     before: `agents/              # leads, managers, writers, analysts`
     after:  `agents/              # lead, writers, analysts`

   - In the Project Structure block under `core/`, remove `scan` from the commands line:

     before: `commands/            # report, ship, scan`
     after:  `commands/            # report, ship`

   - In the `core/` skills line, the list (`branching, commit, gather-git-context, gather-ticket-metadata, ship, system-safety`) is correct.

   - In the Commands table, remove the `/scan` row.

   - Update the headline count in the `/scan` line if it appears anywhere else (a quick grep catches it). The CLAUDE.md row mentioned "all 14 agents" — remove the row entirely.

   - In the Plugin Dependencies prose, the line "Core has soft references to work (context-aware routing) and standards (scan)" should be updated. Change to: "Core has a soft reference to work (context-aware routing in `/report` and `/ship`)." The standards reference goes away with `/scan`.

3. **Update `plugins/core/README.md`.**

   - Remove the `/scan` row from the Commands table.

4. **Sweep `.workaholic/specs/application.md`.**

   This file is the most affected. Rewrite the following sections:

   - **Orchestration Model > Drivin Plugin Orchestration**: Drop "manager agents in the second layer". Re-describe as a three-layer orchestration (commands, leading-aware agents, skills). Remove the entire "Two-Phase Execution Model" subsection.
   - **Command-Level Orchestration Patterns > Scan Command Two-Phase Orchestration**: Delete this subsection (the Mermaid diagram and surrounding prose). Add a one-sentence note that the previous `/scan` command and its two-phase model were retired in favor of direct leading-skill preloads inside the work-plugin commands.
   - **Manager Tier Responsibilities**: Delete this subsection entirely.
   - **Leader Tier Responsibilities**: Replace the per-leader paragraphs (which list 10 leads with manager dependencies) with a paragraph describing the four current leading skills (validity, accessibility, security, availability) and how they are preloaded directly into ticket-organizer, drive, planner, architect, and constructor.
   - **Parallel vs Sequential Execution**: Update the line about "phase 3a" and "phase 3b" — those phases no longer exist. Trim to describe ticket-organizer's three-discoverer parallelism and story-writer's two-phase pattern.
   - **Data Flow > Manager Output Flow**: Delete this subsection (Mermaid diagram and prose).
   - **Documentation Scan Flow**: Delete this subsection.
   - **Execution Lifecycle > Manager Tier Execution**: Delete this subsection.
   - **Architectural Evolution > Addition of Manager Tier**: Replace with a "Removal of Manager Tier" entry that records the evolution: the manager tier was introduced in Feb 2026 to provide strategic context but was removed when leading skills proved sufficient as the canonical policy lens, consulted directly by work-plugin commands and agents.
   - **Assumptions**: Remove the bullets that reference managers, the two-phase execution model, scan phase 3a/3b agent counts, and `.workaholic/constraints/`. Add bullets describing the leading-skill preload pattern in `/ticket`, `/drive`, and `/trip`.

   Update the bilingual partner `application_ja.md` to match.

5. **Sweep `.workaholic/specs/component.md`.**

   - Update the agent/skill inventory counts. The standards plugin now has fewer agents and skills than the previous prose claimed. Recompute from the post-foundation tree.
   - Remove any reference to `manage-*` skills, `*-manager.md` agents, `define-manager.md`, `select-scan-agents`, or the `scan` command.
   - Note the new structure: standards plugin contains leading-* skills, leaders-principle, analyze-*, write-*, review-sections, validate-writer-output; agents are lead, writers (changelog, terms, overview, release-note), analysts (model, performance), section-reviewer.
   - Update `component_ja.md` to match.

6. **Sweep `.workaholic/specs/data.md`.**

   - Remove or rewrite any "Manager Output Flow" or "Constraint Files" sections.
   - Replace with a "Lead Policy Application" section describing how the four leading skills are preloaded into work-plugin agents and consulted at ticket scoping, implementation, and trip time.
   - Update `data_ja.md` to match.

7. **Sweep `.workaholic/specs/infrastructure.md` and `.workaholic/specs/ux.md`.**

   - Read both files. Remove any reference to `/scan`, the manager tier, or the two-phase execution model.
   - In `ux.md`, the user-facing command list should drop `/scan`.
   - Update bilingual partners.

8. **Verify `.workaholic/specs/README.md` does not list manager-owned documents.**

   The previous architecture-manager produced `feature.md` and `usecase.md`. The README index already lists them; do not delete the files (per the foundation ticket scope), but add a footnote in the README that these documents are hand-maintained reference docs without an automated owner.

9. **Final verification grep.**

   ```bash
   grep -rn "manage-\|managers-principle\|architecture-manager\|project-manager\|quality-manager\|select-scan-agents\|/scan\b\|define-manager\|two-phase\|Phase 3a\|Phase 3b" \
     CLAUDE.md plugins/core/README.md .workaholic/specs/ 2>/dev/null \
     | grep -v "manage-branch"
   ```

   Expected: no matches. Investigate and remove any survivors.

## Patches

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,12 +17,12 @@ plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    commands/            # report, ship, scan
+    commands/            # report, ship
     skills/              # branching, commit, gather-git-context, gather-ticket-metadata, ship, system-safety
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    agents/              # leads, managers, writers, analysts
-    skills/              # lead-*, manage-*, analyze-*, write-*
+    agents/              # lead, writers, analysts
+    skills/              # leading-*, leaders-principle, analyze-*, write-*
   work/                  # Work plugin: drive + trip workflows (depends on: core)
     .claude-plugin/      # Plugin configuration
     agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
```

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -126,7 +126,6 @@ Skills are the knowledge layer. Commands and subagents are the orchestration lay
 | `/ticket <description>`          | Write implementation spec for a feature          |
 | `/drive`                         | Implement queued specs one by one                |
-| `/scan`                          | Full documentation scan (all 14 agents)          |
 | `/report`                        | Context-aware: generate story or journey report and create PR |
 | `/ship`                          | Context-aware: merge PR, deploy, and verify      |
 | `/release [major\|minor\|patch]` | Release new marketplace version                  |
```

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -54,7 +54,7 @@ work ─ ─ ─ ─ ─

-Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads, subagent invocations) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Core has soft references to work (context-aware routing) and standards (scan). Work has soft references to standards (lead skill preloads, writer subagent invocations).
+Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads, subagent invocations) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Core has a soft reference to work (context-aware routing in `/report` and `/ship`). Work has soft references to standards (leading skill preloads, writer subagent invocations).
```

### `plugins/core/README.md`

```diff
--- a/plugins/core/README.md
+++ b/plugins/core/README.md
@@ -8,7 +8,6 @@
 | ------- | ----------- |
 | `/report` | Context-aware report generation and PR creation |
 | `/ship` | Context-aware: merge PR, deploy, and verify |
-| `/scan` | Full documentation scan (all agents) |
```

> **Note**: The spec rewrites in `.workaholic/specs/` are too extensive to express as patches. Implement them via Edit/Write following the implementation steps. The specs are reference documents and benefit from a clean rewrite of the affected sections rather than narrow diffs.

## Considerations

- **Bilingual specs**: Each spec has a `*_ja.md` partner. Update both consistently. The translation policy lives in CLAUDE.md or the analysts; follow whatever convention is already in place. If unsure, write English first and translate as a follow-up step in the same commit. (`.workaholic/specs/*_ja.md`)
- **Commit verb category**: This is a `housekeeping` ticket. The commit category will be `Changed` (most edits update existing prose; only `/scan` is fully removed from CLAUDE.md and core README). The archive script chooses the category from the commit verb; default to `Update`. (`plugins/work/skills/drive/scripts/archive.sh`)
- **Spec ownership going forward**: The foundation ticket establishes that `.workaholic/specs/` are hand-maintained reference docs without an automated owner. This ticket adds a one-line note to `.workaholic/specs/README.md` to make that explicit so future contributors know to update specs through `/ticket` rather than expecting `/scan` to refresh them. (`.workaholic/specs/README.md`)
- **Stories and release notes are historical**: The scope explicitly excludes `.workaholic/stories/*.md`, `CHANGELOG.md`, and release notes. Do not edit them — they record the project's history accurately as of when they were written, and rewriting them would falsify that record. (`.workaholic/stories/`, `CHANGELOG.md`, `.workaholic/release-notes/`)
- **`/scan` references in archived tickets**: Archived tickets in `.workaholic/tickets/archive/` reference `/scan` and the manager tier extensively. Do not edit those — they are historical records. The grep in step 9 deliberately excludes the archive directory. (`.workaholic/tickets/archive/`)
- **`stakeholder.md` orphan**: The current specs index lists a `stakeholder.md` file. The `analyze-viewpoint` skill produces it. Verify that file still has an owner (`analyze-viewpoint` plus an analyst agent or writer); if not, add it to the README footnote about hand-maintained specs. (`.workaholic/specs/stakeholder.md`, `plugins/standards/skills/analyze-viewpoint/SKILL.md`)
- **Cross-reference**: This ticket depends on both `20260509001215-eliminate-manager-tier.md` and `20260509001216-wire-leads-into-work-flows.md`. It is the last ticket in the series and produces no further dependents.
- **No version bump**: Per the foundation ticket's Considerations, plugin version bumps and `/release` happen after `/drive` finishes implementing all three tickets. Do not modify any `plugin.json` `version` fields here.
