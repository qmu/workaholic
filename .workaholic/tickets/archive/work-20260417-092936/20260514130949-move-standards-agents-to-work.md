---
created_at: 2026-05-14T13:09:49+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: b1cc36b
category: Changed
depends_on:
---

# Move standards agents to work plugin

## Overview

Relocate every file currently under `plugins/standards/agents/` into `plugins/work/agents/`. All eight agents (`changelog-writer`, `lead`, `model-analyst`, `overview-writer`, `performance-analyst`, `release-note-writer`, `section-reviewer`, `terms-writer`) are workflow orchestration: they invoke skills, run scripts, and return JSON. Under the consolidated plugin boundary, code-aware and workflow-aware orchestration belongs in `work`; `standards` is being reduced to a pure policy/standards plugin that contains only `leading-*` skills. This ticket performs the agent moves and rewrites every `${CLAUDE_PLUGIN_ROOT}` path that flips direction, every frontmatter `skills:` entry that crosses the boundary, and every `Task` invocation site that names a moved agent.

Companion tickets:

- `20260514130950-move-non-leading-skills-to-core.md` — relocates the non-leading skills the moved agents preload. Until that ticket lands, the moved agents preload these skills via `standards:` prefixes (cross-plugin from work to standards). After that ticket lands, the entries become `core:` prefixes (cross-plugin from work to core via the declared dependency). This ticket therefore writes the `standards:` prefix; the companion's reconciliation step finalizes it.
- `20260514130951-move-standards-rules-to-work.md` — relocates `plugins/standards/rules/` into `plugins/work/rules/`. Independent of this ticket; ordering does not matter.

After all three tickets land, `plugins/standards/` contains only `skills/leading-*` plus its `.claude-plugin/` manifest.

## Key Files

### Agent files to move (each entire file)

- `plugins/standards/agents/changelog-writer.md` -> `plugins/work/agents/changelog-writer.md`
- `plugins/standards/agents/lead.md` -> `plugins/work/agents/lead.md`
- `plugins/standards/agents/model-analyst.md` -> `plugins/work/agents/model-analyst.md`
- `plugins/standards/agents/overview-writer.md` -> `plugins/work/agents/overview-writer.md`
- `plugins/standards/agents/performance-analyst.md` -> `plugins/work/agents/performance-analyst.md`
- `plugins/standards/agents/release-note-writer.md` -> `plugins/work/agents/release-note-writer.md`
- `plugins/standards/agents/section-reviewer.md` -> `plugins/work/agents/section-reviewer.md`
- `plugins/standards/agents/terms-writer.md` -> `plugins/work/agents/terms-writer.md`

### Path rewrites inside the moved files (same-plugin -> cross-plugin direction flips)

Every `${CLAUDE_PLUGIN_ROOT}/skills/<non-leading-skill>/scripts/...` path inside a moved agent currently resolves to `plugins/standards/skills/<non-leading-skill>/scripts/...` (same-plugin while the agent lived in standards). After the move, the agent lives in work, but the referenced skills are still in standards (until the companion skills-move ticket lands). Therefore every such inline path must become `${CLAUDE_PLUGIN_ROOT}/../standards/skills/<non-leading-skill>/scripts/...`.

- `plugins/work/agents/model-analyst.md` lines 26, 31 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/{gather,read-overrides}.sh` -> `${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-viewpoint/scripts/{gather,read-overrides}.sh`
- `plugins/work/agents/overview-writer.md` line 25 - `${CLAUDE_PLUGIN_ROOT}/skills/write-overview/scripts/collect-commits.sh` -> `${CLAUDE_PLUGIN_ROOT}/../standards/skills/write-overview/scripts/collect-commits.sh`
- `plugins/work/agents/performance-analyst.md` line 18 - `${CLAUDE_PLUGIN_ROOT}/skills/analyze-performance/scripts/calculate.sh` -> `${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-performance/scripts/calculate.sh`
- `plugins/work/agents/terms-writer.md` line 23 - `${CLAUDE_PLUGIN_ROOT}/skills/write-terms/scripts/gather.sh` -> `${CLAUDE_PLUGIN_ROOT}/../standards/skills/write-terms/scripts/gather.sh`

`changelog-writer.md`, `release-note-writer.md`, `section-reviewer.md`, and `lead.md` do not contain inline `${CLAUDE_PLUGIN_ROOT}` paths -- their skill usage is via frontmatter preload only.

### Frontmatter `skills:` rewrites inside the moved files (same-plugin -> cross-plugin)

Currently every moved agent lists its supporting skill unprefixed (same-plugin within standards). After the move into work, those entries must point cross-plugin into standards.

- `plugins/work/agents/changelog-writer.md` line 6 - `- write-changelog` -> `- standards:write-changelog`
- `plugins/work/agents/lead.md` lines 6-12 - `- leading-validity`, `- leading-availability`, `- leading-security`, `- leading-accessibility`, `- analyze-policy`, `- analyze-viewpoint`, `- write-spec` all gain the `standards:` prefix.
- `plugins/work/agents/model-analyst.md` lines 6-7 - `- analyze-viewpoint`, `- write-spec` -> `- standards:analyze-viewpoint`, `- standards:write-spec`
- `plugins/work/agents/overview-writer.md` line 7 - `- write-overview` -> `- standards:write-overview`
- `plugins/work/agents/performance-analyst.md` lines 6-7 - `- core:gather-git-context` stays as-is (already correctly prefixed); `- analyze-performance` -> `- standards:analyze-performance`
- `plugins/work/agents/release-note-writer.md` line 6 - `- write-release-note` -> `- standards:write-release-note`
- `plugins/work/agents/section-reviewer.md` line 7 - `- review-sections` -> `- standards:review-sections`
- `plugins/work/agents/terms-writer.md` line 6 - `- write-terms` -> `- standards:write-terms`

> **Note**: These `standards:` prefixes are the correct cross-plugin form *while the skills still live in standards*. Once the companion ticket `20260514130950-move-non-leading-skills-to-core.md` relocates the non-leading skills into core, every entry above (except `standards:leading-*`) must be re-prefixed to `core:`. The companion ticket owns that reconciliation; this ticket leaves the entries pointing at the current location of each skill.

### Caller updates: `Task` invocations of moved agents

The work plugin already uses `standards:overview-writer`, `standards:section-reviewer`, and `standards:release-note-writer` in `story-writer.md`. After the move these become same-plugin invocations and the prefix is dropped (work calling work needs no prefix).

- `plugins/work/agents/story-writer.md` line 25 - `subagent_type: "standards:overview-writer"` -> `subagent_type: "work:overview-writer"`
- `plugins/work/agents/story-writer.md` line 26 - `subagent_type: "standards:section-reviewer"` -> `subagent_type: "work:section-reviewer"`
- `plugins/work/agents/story-writer.md` line 50 - `subagent_type: "standards:release-note-writer"` -> `subagent_type: "work:release-note-writer"`

Convention check: existing `Task` calls within work agents use the explicit plugin prefix (e.g., `subagent_type: "work:pr-creator"`, `subagent_type: "work:release-readiness"`). To stay consistent with that convention, the rewrites above use `work:<agent>` rather than the bare name.

Other potential callers were audited:

- `plugins/standards/agents/` itself contained no inter-agent `Task` invocations (each agent stands alone).
- `plugins/core/` and `plugins/work/commands/` contain no `Task` invocations of `changelog-writer`, `model-analyst`, `performance-analyst`, `terms-writer`, or `lead`. These agents are not currently wired into any command path; the move is purely structural.

### Manifest updates

- `plugins/work/.claude-plugin/plugin.json` -- `dependencies: ["core"]` is unchanged. Standards is *not* added as a hard dependency because the cross-plugin references from work agents into `plugins/standards/skills/leading-*` and (interim) `plugins/standards/skills/{analyze,write,review,validate}-*` are soft references (skill preloads). The "Work has soft references to standards" line in `CLAUDE.md` already documents this posture.
- `plugins/standards/.claude-plugin/plugin.json` -- `dependencies: []` is unchanged. Standards has no remaining outgoing references after the agents leave.

### Documentation updates

- `CLAUDE.md` lines 21-23 - the `standards/` block currently lists `agents/ # lead, writers, analysts` and `skills/ # leading-*, analyze-*, write-*`. After this ticket only `skills/` remains under standards; the `agents/` bullet is deleted. The `skills/` line is reconciled by the companion skills-move ticket (which leaves only `leading-*` once the non-leading skills are gone).
- `CLAUDE.md` lines 25-30 - the `work/` block's `agents/` line currently reads `agents/ # drive-navigator, story-writer, planner, architect, constructor, etc.` -- the listing remains accurate (the existing "etc." absorbs the eight new agents) but if more explicit enumeration is desired the comment may be expanded to mention the writer/analyst families. Leaving as-is is acceptable.

## Related History

The two most recent reorganizations (`20260514121259-move-work-skills-to-core.md` and `20260514121300-move-report-ship-commands-to-work.md`) established the path-rewrite playbook this ticket follows: `git mv` files, flip `${CLAUDE_PLUGIN_ROOT}` prefixes, flip frontmatter `skills:` prefixes, update `Task` invocation prefixes, update `CLAUDE.md`. The earlier work-plugin merge and core/standards reorganizations provide the same pattern at smaller scale.

Past tickets that touched similar areas:

- [20260514121259-move-work-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514121259-move-work-skills-to-core.md) - Most recent boundary redraw. Defines the exact rewrite mechanics: `git mv`, frontmatter prefix flips, `${CLAUDE_PLUGIN_ROOT}/../<plugin>/...` inline path flips, hook message updates, and `CLAUDE.md` Project Structure edits. This ticket reuses the same mechanics in a different direction (standards -> work for agents).
- [20260514121300-move-report-ship-commands-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514121300-move-report-ship-commands-to-work.md) - Companion move that finalized the core/work boundary; documents the "interim state, then companion ticket reconciles" pattern this ticket applies to the standards/work boundary.
- [20260404014400-create-work-plugin-merge-drivin-trippin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014400-create-work-plugin-merge-drivin-trippin.md) - Created the `work` plugin and established the convention of explicit plugin prefixes in `Task` invocations (`work:<agent>`).
- [20260404014402-update-core-crossrefs-for-work-plugin.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014402-update-core-crossrefs-for-work-plugin.md) - The comprehensive cross-reference audit pattern that this ticket reuses (every `${CLAUDE_PLUGIN_ROOT}` path and every `skills:` entry).
- [f6869f2 commit -- Deprecate leaders-principle; merge Vendor Neutrality and Ubiquitous Language into leads](https://github.com/) - Most recent edit to the lead-related agents and skills; confirms `lead.md` is purely a parameterized orchestration shell with all domain knowledge living in the `leading-*` skills, supporting the conclusion that `lead.md` belongs in work alongside the other orchestrators.

## Implementation Steps

1. **Move agent files.** Use `git mv` for each of the eight files to preserve history:
   ```
   git mv plugins/standards/agents/changelog-writer.md   plugins/work/agents/changelog-writer.md
   git mv plugins/standards/agents/lead.md               plugins/work/agents/lead.md
   git mv plugins/standards/agents/model-analyst.md      plugins/work/agents/model-analyst.md
   git mv plugins/standards/agents/overview-writer.md    plugins/work/agents/overview-writer.md
   git mv plugins/standards/agents/performance-analyst.md plugins/work/agents/performance-analyst.md
   git mv plugins/standards/agents/release-note-writer.md plugins/work/agents/release-note-writer.md
   git mv plugins/standards/agents/section-reviewer.md   plugins/work/agents/section-reviewer.md
   git mv plugins/standards/agents/terms-writer.md       plugins/work/agents/terms-writer.md
   ```
   Confirm `plugins/standards/agents/` is empty. The empty directory may be removed (git will drop it).

2. **Rewrite inline `${CLAUDE_PLUGIN_ROOT}` paths in moved files.** For each moved agent that contains a `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/...` reference (see "Path rewrites" above), insert `../standards/` after the variable: `${CLAUDE_PLUGIN_ROOT}/../standards/skills/<skill>/scripts/...`. Apply to `model-analyst.md`, `overview-writer.md`, `performance-analyst.md`, and `terms-writer.md`.

3. **Rewrite frontmatter `skills:` lists in moved files.** For each moved agent, prepend `standards:` to every preload that names a non-`core:` skill (see "Frontmatter `skills:` rewrites" above). For `lead.md`, this affects all seven entries (`leading-{validity,availability,security,accessibility}`, `analyze-policy`, `analyze-viewpoint`, `write-spec`). For the other seven agents, it affects their single non-core preload entry.

4. **Update `Task` invocations in `plugins/work/agents/story-writer.md`.** Change the three `subagent_type` values: `standards:overview-writer` -> `work:overview-writer`, `standards:section-reviewer` -> `work:section-reviewer`, `standards:release-note-writer` -> `work:release-note-writer`. Body prose mentioning the agent names ("Invoke **overview-writer**") needs no change.

5. **Update `CLAUDE.md` Project Structure.** Edit the standards block at lines 21-24: delete the `agents/ # lead, writers, analysts` line entirely. Leave the `skills/` line for the companion ticket to reconcile. The work block at lines 25-30 keeps its `agents/` line as-is (the existing comment already says "etc." and absorbs the new agents).

6. **Verification pass.**
   - `ls plugins/standards/agents/` must return no files (directory may be present or removed).
   - `grep -rn 'subagent_type.*standards:' plugins/work` must return zero matches (every `Task` call into a moved agent must now use `work:`).
   - `grep -rn '\${CLAUDE_PLUGIN_ROOT}/skills/\(analyze-\|write-\|review-\|validate-\)' plugins/work/agents` must return zero matches (every script reference into a non-leading standards skill must use `../standards/`).
   - `grep -rn '^  - \(write-\|analyze-\|review-\|validate-\|leading-\)' plugins/work/agents` (frontmatter only) must return zero unprefixed matches -- every such entry must be prefixed `standards:` or `core:`.
   - Invoke `/report` from a `work-*` branch end-to-end to confirm `story-writer` can still launch the three moved writer/reviewer agents through their new `work:` prefixes. The agents themselves should still load their preloaded `standards:<skill>` entries via the soft-reference loader (no `plugin.json` dependency change required because they are skill preloads, not declared dependencies).

## Considerations

- **Interim state for skill preloads.** Between this ticket landing and the companion `20260514130950-move-non-leading-skills-to-core.md` landing, the moved agents preload skills via `standards:<skill>` prefixes. This is correct *because the skills still live in standards*. Once the companion ticket relocates those skills, every `standards:<non-leading-skill>` entry in the moved agents (and every `${CLAUDE_PLUGIN_ROOT}/../standards/skills/<non-leading>/...` path) must be re-rewritten to `core:` form. The companion ticket explicitly owns this reconciliation; if it lands first, the entries in *this* ticket should already be `core:` instead of `standards:`. Implementers should check the current location of each skill before applying frontmatter prefixes. (`plugins/standards/skills/`, `plugins/core/skills/`)
- **No new hard dependencies.** `plugins/work/.claude-plugin/plugin.json` retains `dependencies: ["core"]`. Cross-plugin skill preloads from work into standards (whether `standards:leading-*` or interim `standards:<non-leading>`) are soft references, which the loader tolerates without a manifest entry. The "Work has soft references to standards" sentence in `CLAUDE.md` already documents this. After the companion skills-move ticket lands, the only remaining soft references from work into standards are the four `leading-*` skills, exactly as the architecture intends. (`plugins/work/.claude-plugin/plugin.json`, `CLAUDE.md` line 52)
- **`lead.md` confirmed as orchestration.** The `lead` agent is a parameterized shell: the caller passes a domain name (e.g., `"Domain: security"`) and the agent applies the matching `leading-<domain>` skill. All domain-specific knowledge lives in the `leading-*` skills (which stay in standards). Moving `lead.md` into work does not relocate any policy content; it only relocates the workflow-step orchestrator that consumes that policy content. This matches the user's stated intent ("only the actual standards and policies, like leading-prefix skills, only in this plugin"). (`plugins/standards/agents/lead.md`, `.claude/rules/define-lead.md` Agent section)
- **`Task` prefix convention: `work:` not bare.** Existing work-agent `Task` calls in `story-writer.md` use explicit `work:pr-creator` and `work:release-readiness` prefixes. Same-plugin invocations work both prefixed and unprefixed, but using `work:` keeps the call sites uniform and discoverable. The verification grep (`subagent_type.*standards:`) catches the migration; a follow-up cleanup pass could normalize any future implicit forms. (`plugins/work/agents/story-writer.md` lines 24-26, 50)
- **Validity lens (Ours/Theirs Layer Segregation, Ubiquitous Language).** Pulling workflow-orchestrating agents into `work` and leaving `standards` as a pure policy/standards plugin sharpens the "ours/theirs" segregation that `standards:leading-validity` advocates: standards is the "policy theirs" that work consumes via declared (soft) interfaces; work is the "domain ours" where workflow choices live. The ubiquitous-language principle is preserved -- agent basenames (`lead`, `terms-writer`, `model-analyst`) are unchanged, so existing references in prose and historical tickets remain meaningful. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens (Vendor Neutrality, IaC).** No external dependencies are introduced; the move is purely internal restructuring. `git mv` preserves blame and history, satisfying the observability concern. The "work soft-references standards" relationship is documented in `CLAUDE.md` and matches the loader's actual behavior, so the architecture stays auditable from source. (`plugins/standards/skills/leading-availability/SKILL.md`)
- **Order independence with companion tickets.** This ticket is mechanically independent from `20260514130950-move-non-leading-skills-to-core.md` and `20260514130951-move-standards-rules-to-work.md`. All three edit `CLAUDE.md`; the reconciliation pattern matches the recent two-ticket precedent (each ticket owns its slice of the Project Structure block). `depends_on` is left empty.

## Patches

### `plugins/work/agents/story-writer.md`

```diff
--- a/plugins/work/agents/story-writer.md
+++ b/plugins/work/agents/story-writer.md
@@ -22,8 +22,8 @@
 Invoke 3 agents in parallel via Task tool (single message with 3 tool calls):

 - **release-readiness** (`subagent_type: "work:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
-- **overview-writer** (`subagent_type: "standards:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
-- **section-reviewer** (`subagent_type: "standards:section-reviewer"`, `model: "opus"`): Generates sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns). Pass branch name and archived tickets list.
+- **overview-writer** (`subagent_type: "work:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
+- **section-reviewer** (`subagent_type: "work:section-reviewer"`, `model: "opus"`): Generates sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns). Pass branch name and archived tickets list.

 Wait for all 3 agents to complete. Track which succeeded and which failed.

@@ -47,7 +47,7 @@

 1. **Create PR** first: Invoke **pr-creator** (`subagent_type: "work:pr-creator"`, `model: "opus"`). Reads story file, derives title, runs `gh` CLI operations. Capture PR URL from response.

-2. **Generate release note** with PR URL: Invoke **release-note-writer** (`subagent_type: "standards:release-note-writer"`, `model: "haiku"`). Pass the PR URL obtained from pr-creator in the prompt. Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.
+2. **Generate release note** with PR URL: Invoke **release-note-writer** (`subagent_type: "work:release-note-writer"`, `model: "haiku"`). Pass the PR URL obtained from pr-creator in the prompt. Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.

 Capture PR URL from pr-creator response for final output.
```

### `plugins/work/agents/lead.md` (post-move)

```diff
--- a/plugins/standards/agents/lead.md
+++ b/plugins/work/agents/lead.md
@@ -3,11 +3,11 @@
 description: Parameterized lead agent that owns a specific policy or viewpoint domain. Receives the domain as a prompt parameter and applies the corresponding lead skill.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - leading-validity
-  - leading-availability
-  - leading-security
-  - leading-accessibility
-  - analyze-policy
-  - analyze-viewpoint
-  - write-spec
+  - standards:leading-validity
+  - standards:leading-availability
+  - standards:leading-security
+  - standards:leading-accessibility
+  - standards:analyze-policy
+  - standards:analyze-viewpoint
+  - standards:write-spec
 ---
```

### `plugins/work/agents/model-analyst.md` (post-move)

```diff
--- a/plugins/standards/agents/model-analyst.md
+++ b/plugins/work/agents/model-analyst.md
@@ -3,8 +3,8 @@
 description: Analyze repository from model viewpoint and generate spec documentation.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - analyze-viewpoint
-  - write-spec
+  - standards:analyze-viewpoint
+  - standards:write-spec
 ---

 # Model Analyst
@@ -23,12 +23,12 @@

 1. **Gather Context**: Run:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/gather.sh model main
+   bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-viewpoint/scripts/gather.sh model main
    ```

 2. **Check Overrides**: Run:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-viewpoint/scripts/read-overrides.sh
+   bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-viewpoint/scripts/read-overrides.sh
    ```
    If overrides exist for this viewpoint, incorporate them into your analysis.
```

### `plugins/work/agents/overview-writer.md` (post-move)

```diff
--- a/plugins/standards/agents/overview-writer.md
+++ b/plugins/work/agents/overview-writer.md
@@ -4,7 +4,7 @@
 tools: Read, Bash, Glob, Grep
 model: haiku
 skills:
-  - write-overview
+  - standards:write-overview
 ---

 # Overview Writer
@@ -22,7 +22,7 @@

 1. **Collect Commits**: Run the write-overview skill script:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/write-overview/scripts/collect-commits.sh <base-branch>
+   bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/write-overview/scripts/collect-commits.sh <base-branch>
    ```
```

### `plugins/work/agents/performance-analyst.md` (post-move)

```diff
--- a/plugins/standards/agents/performance-analyst.md
+++ b/plugins/work/agents/performance-analyst.md
@@ -3,7 +3,7 @@
 description: Evaluate decision-making quality across five viewpoints
 skills:
   - core:gather-git-context
-  - analyze-performance
+  - standards:analyze-performance
 ---

 # Performance Analyst
@@ -15,7 +15,7 @@
 1. **Gather context** using the preloaded gather-git-context skill
 2. **Calculate metrics** using the preloaded analyze-performance skill:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-performance/scripts/calculate.sh <base_branch>
+   bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/analyze-performance/scripts/calculate.sh <base_branch>
    ```
 3. **Analyze performance** following the preloaded analyze-performance skill for evaluation framework, output format, and guidelines
```

### `plugins/work/agents/terms-writer.md` (post-move)

```diff
--- a/plugins/standards/agents/terms-writer.md
+++ b/plugins/work/agents/terms-writer.md
@@ -3,7 +3,7 @@
 description: Update .workaholic/terms/ documentation to maintain consistent term definitions. Use after completing implementation work.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - write-terms
+  - standards:write-terms
 ---

 # Terms Writer
@@ -19,7 +19,7 @@

 1. **Gather Context**: Use the "Gather Context" section of the preloaded write-terms skill:
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/skills/write-terms/scripts/gather.sh [base-branch]
+   bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/write-terms/scripts/gather.sh [base-branch]
    ```
    Read archived tickets if they exist, otherwise use diff output.
```

### `plugins/work/agents/changelog-writer.md` (post-move)

```diff
--- a/plugins/standards/agents/changelog-writer.md
+++ b/plugins/work/agents/changelog-writer.md
@@ -3,7 +3,7 @@
 description: Update root CHANGELOG.md from archived tickets. Groups entries by category and links to commits and tickets.
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
-  - write-changelog
+  - standards:write-changelog
 ---
```

### `plugins/work/agents/release-note-writer.md` (post-move)

```diff
--- a/plugins/standards/agents/release-note-writer.md
+++ b/plugins/work/agents/release-note-writer.md
@@ -3,7 +3,7 @@
 description: Generate release notes from branch story for GitHub Releases.
 tools: Read, Write, Glob, Grep
 skills:
-  - write-release-note
+  - standards:write-release-note
 ---
```

### `plugins/work/agents/section-reviewer.md` (post-move)

```diff
--- a/plugins/standards/agents/section-reviewer.md
+++ b/plugins/work/agents/section-reviewer.md
@@ -4,7 +4,7 @@
 tools: Read, Glob, Grep
 model: haiku
 skills:
-  - review-sections
+  - standards:review-sections
 ---
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -20,7 +20,6 @@
     skills/              # branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, ship, system-safety, trip-protocol
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    agents/              # lead, writers, analysts
     skills/              # leading-*, analyze-*, write-*
   work/                  # Work plugin: drive + trip workflows (depends on: core)
     .claude-plugin/      # Plugin configuration
```

> **Note**: The `skills/` listing under `standards/` ("`leading-*, analyze-*, write-*`") becomes "`leading-*`" after the companion skills-move ticket lands. This patch leaves that line alone; the companion ticket reconciles it.

## Final Report

Development completed as planned. All four verification greps returned zero stale references (no `standards:` Task calls in work, no same-plugin paths into moved skills, no unprefixed leading/analyze/write/review entries in work agents, standards/agents/ empty).

### Discovered Insights

- **Insight**: The `performance-analyst` agent already carried a correctly prefixed `core:gather-git-context` entry alongside its standards-resident `analyze-performance` entry. This mixed-prefix layout (some preloads cross-plugin to core, others same-plugin or cross-plugin to standards) is the natural steady state for an agent that consumes both reusable workflow skills (core) and policy/analytical frameworks (standards). The companion skills-move ticket will collapse the standards entries to core, leaving the agent with only `core:` preloads.
  **Context**: A useful checkpoint when migrating agents: an agent that ends up preloading only `core:` skills is "code-agnostic enough" that it could be moved to core; one that still preloads `standards:` policy skills must stay in work. After the companion ticket, this property gives a clear rule for any future agent placement decision.
- **Insight**: Three `Task` invocations in `story-writer.md` used the explicit `standards:<agent>` prefix even though the agents were previously cross-plugin from work. The convention "always use the plugin prefix in `Task` calls" made the migration mechanically simple — a single grep found every call site, and the rewrite was character-for-character. Convention has refactor cost; this is a payoff.
  **Context**: When designing cross-plugin invocation patterns, prefer "always prefix" over "prefix only when crossing a boundary." The former is robust under reorganization; the latter requires updates whenever a boundary moves.
