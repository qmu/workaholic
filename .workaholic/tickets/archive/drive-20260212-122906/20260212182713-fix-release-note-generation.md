---
created_at: 2026-02-12T18:27:13+08:00
author: a@qmu.jp
type: bugfix
layer: [Domain, Config]
effort: 0.5h
commit_hash: d05573e
category: Changed
---

# Fix Release Note Generation

## Overview

The release note generation has three issues: (1) the H1 heading uses the branch name (e.g., "# Release Notes: drive-20260208-131649") which is meaningless to readers -- it should use the story title (the PR title derived from the first highlight) as a descriptive H1 instead, (2) the PR URL link is frequently missing because the release-note-writer runs in parallel with pr-creator in Phase 4 of story-writer and has no access to the PR URL, and (3) the `## Changes` section with Added/Changed/Removed categorization and the `Velocity` metric that appeared in earlier release notes (e.g., drive-20260208-131649) have disappeared from the skill template. All three issues are in the write-release-note skill and the release-note-writer agent.

## Key Files

- `plugins/core/skills/write-release-note/SKILL.md` - Skill template defining the release note content structure; missing H1 with story title, missing Changes section, missing Velocity metric
- `plugins/core/agents/release-note-writer.md` - Agent that orchestrates release note generation; needs to extract story title and receive PR URL
- `plugins/core/agents/story-writer.md` - Orchestrator that invokes release-note-writer in Phase 4 parallel with pr-creator; needs to pass PR URL to release-note-writer or reorder phases
- `plugins/core/skills/create-pr/SKILL.md` - PR creation skill that derives the PR title from the first story highlight (same logic needed for H1)

## Related History

The release-note-writer was introduced in drive-20260204-160722 and has already been patched once for hardcoded metric values. The original implementation ticket explicitly mentioned "key indicators" in the skill design, but the subsequent template evolution lost the Changes categorization and Velocity metric that appeared in the drive-20260208 release note.

Past tickets that touched similar areas:

- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Created release-note-writer and write-release-note skill (same files)
- [20260210125506-fix-release-note-hardcoded-metrics.md](.workaholic/tickets/archive/drive-20260210-121635/20260210125506-fix-release-note-hardcoded-metrics.md) - Fixed hardcoded metric placeholders in write-release-note skill (same files)

## Implementation Steps

1. **Update write-release-note skill template** (`plugins/core/skills/write-release-note/SKILL.md`):
   - Add H1 heading using the story title (first highlight from the Overview section, same derivation as PR title in create-pr skill)
   - Add `## Changes` section with `### Added`, `### Changed`, `### Removed` subsections derived from archived ticket `category` frontmatter and summaries in the story's Section 4
   - Add `Velocity` metric line to the Metrics section (extracted from story frontmatter `velocity` and `velocity_unit` fields)
   - Add `[Pull Request](PR-URL)` instruction noting that PR URL is passed as input

2. **Update release-note-writer agent** (`plugins/core/agents/release-note-writer.md`):
   - Add instruction to extract the story title from the first highlight in Section 1 Overview for the H1 heading
   - Add instruction to read Section 4 (Changes) from the story to populate the Changes section with categorized entries
   - Add instruction to extract `velocity` and `velocity_unit` from story frontmatter for Velocity metric
   - Document that PR URL is received as input and must be included in Links section

3. **Update story-writer orchestration** (`plugins/core/agents/story-writer.md`):
   - Reorder Phase 4 so that pr-creator runs first (or in a prior step), then pass the PR URL to release-note-writer
   - Alternatively, split Phase 4 into two sequential steps: (a) create PR and capture URL, (b) generate release note with PR URL as input
   - Update Phase 5 commit to include release notes

## Patches

### `plugins/core/skills/write-release-note/SKILL.md`

```diff
--- a/plugins/core/skills/write-release-note/SKILL.md
+++ b/plugins/core/skills/write-release-note/SKILL.md
@@ -11,6 +11,8 @@
 ## Content Structure

 ```markdown
+# <Story Title>
+
 ## Summary

 <2-3 sentence overview extracted from story section 1>
@@ -21,12 +23,26 @@
 - <Highlight 2 from story>
 - <Highlight 3 from story>

+## Changes
+
+### Added
+- <Entry from story Section 4 where ticket category is "Added">
+
+### Changed
+- <Entry from story Section 4 where ticket category is "Changed">
+
+### Removed
+- <Entry from story Section 4 where ticket category is "Removed">
+
 ## Metrics

 - **Tickets Completed**: <tickets_completed from frontmatter>
 - **Commits**: <commits from frontmatter>
 - **Duration**: <duration_days from frontmatter> days (<duration_hours from frontmatter> hours)
+- **Velocity**: <velocity from frontmatter> commits/<velocity_unit from frontmatter>

 ## Links

@@ -38,9 +54,19 @@

 1. **Summary**: Extract the essence of section 1 (Overview) from the story. Keep it under 50 words.

-2. **Key Changes**: Use the highlights from section 1. If fewer than 3 highlights, summarize the most impactful changes from section 4 (Changes).
+2. **Story Title (H1)**: Extract the first highlight from section 1 (Overview). Use the same derivation logic as PR title: first highlight text, appending "etc" if multiple highlights exist.
+
+3. **Key Changes**: Use the highlights from section 1. If fewer than 3 highlights, summarize the most impactful changes from section 4 (Changes).
+
+4. **Changes**: Group entries from story Section 4 by their ticket `category` frontmatter (Added, Changed, Removed). Each entry should be a concise one-line summary of the ticket change. Omit empty subsections.

-3. **Metrics**: Extract from story frontmatter:
+5. **Metrics**: Extract from story frontmatter:
    - `tickets_completed` field
    - `commits` field
    - `duration_hours` field (round to 1 decimal place)
    - `duration_days` field (use when available)
    - Format duration as: "N days (N hours)" when both fields exist, "N hours" when only hours exist
+   - `velocity` field (round to 1 decimal place)
+   - `velocity_unit` field
+   - Format velocity as: "N commits/<unit>"

-4. **Links**: Include absolute GitHub URLs when available.
+6. **Links**: PR URL is provided as input to the release-note-writer agent. Always include it.
```

> **Note**: This patch is speculative - the exact line numbers and context may differ. Verify before applying.

### `plugins/core/agents/release-note-writer.md`

```diff
--- a/plugins/core/agents/release-note-writer.md
+++ b/plugins/core/agents/release-note-writer.md
@@ -14,12 +14,16 @@

 ### Step 1: Read Story File

-Read the story file at `.workaholic/stories/<branch-name>.md`.
+Read the story file at `.workaholic/stories/<branch-name>.md`. The PR URL is provided as input.

 Extract:
 - Overview from section 1
 - Highlights from section 1
+- First highlight for H1 title (same derivation as PR title)
 - Frontmatter metrics (tickets_completed, commits, duration_hours, duration_days)
+- Frontmatter metrics (velocity, velocity_unit)
+- Section 4 (Changes) entries with their ticket categories
+- PR URL from input

 ### Step 2: Generate Release Note

@@ -28,8 +32,10 @@
 Create the release note with:
+- H1 title (first highlight, append "etc" if multiple highlights)
 - Summary (2-3 sentences from Overview)
 - Key Changes (highlights as bullet points)
+- Changes (grouped by category: Added, Changed, Removed from Section 4)
 - Metrics (from frontmatter)
   - **Important**: Always use the actual numeric values from the story frontmatter. Never use example or placeholder values.
   - Format duration using both `duration_days` and `duration_hours` when available.
-- Links (PR URL if available, story file path)
+  - Include velocity metric.
+- Links (PR URL from input, story file path)
```

> **Note**: This patch is speculative - verify exact line positions before applying.

### `plugins/core/agents/story-writer.md`

```diff
--- a/plugins/core/agents/story-writer.md
+++ b/plugins/core/agents/story-writer.md
@@ -43,13 +43,17 @@
 ### Phase 4: Generate Release Note and Create PR

-Invoke 2 agents in parallel via Task tool (single message with 2 tool calls):
+Run sequentially:
+
+1. **Create PR** first: Invoke **pr-creator** (`subagent_type: "core:pr-creator"`, `model: "opus"`). Reads story file, derives title, runs `gh` CLI operations. Capture PR URL from response.

-- **release-note-writer** (`subagent_type: "core:release-note-writer"`, `model: "haiku"`): Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.
-- **pr-creator** (`subagent_type: "core:pr-creator"`, `model: "opus"`): Reads story file, derives title, runs `gh` CLI operations.
+2. **Generate release note** with PR URL: Invoke **release-note-writer** (`subagent_type: "core:release-note-writer"`, `model: "haiku"`). Pass the PR URL obtained from pr-creator. Reads story file, generates concise release notes, writes to `.workaholic/release-notes/<branch-name>.md`.

-Wait for both agents to complete. Capture PR URL from pr-creator response.
+Capture PR URL from pr-creator response for final output.
```

> **Note**: This patch is speculative - the parallel-to-sequential change is a design decision. Verify before applying.

## Considerations

- Changing Phase 4 from parallel to sequential introduces a slight performance regression since pr-creator must complete before release-note-writer starts (`plugins/core/agents/story-writer.md` lines 46-51). An alternative is to keep them parallel and have a post-Phase-5 step that patches the PR URL into the release note file, but sequential is simpler and the delay is minimal.
- The `category` field in archived ticket frontmatter is set by the `update-ticket-frontmatter` skill during archiving (`plugins/core/skills/create-ticket/SKILL.md` lines 88-90). The release-note-writer reads the story file which includes Section 4 (Changes) but not the raw ticket frontmatter. The Changes section must be derived from Section 4 subsection titles and summaries, which may not always have explicit Added/Changed/Removed categorization. The story-writer would need to include category information in Section 4, or the release-note-writer would need to read archived tickets directly.
- The `velocity` and `velocity_unit` frontmatter fields are only present when the performance-analyst successfully runs (`plugins/core/skills/write-story/SKILL.md` line 211). The Velocity metric line should be omitted gracefully when these fields are absent.
- The H1 title derivation logic must match the PR title derivation in `plugins/core/skills/create-pr/SKILL.md` lines 14-22 (first highlight, append "etc" if multiple). Keeping these in sync across two skills creates a DRY concern; consider extracting the title derivation rule into a shared guideline if divergence becomes a problem.
- The GitHub Actions release workflow (`/.github/workflows/release.yml` line 67) uses `ls -t` to find the most recent release note file by modification time, which may pick the wrong file if multiple release notes exist. This is a separate issue from the three being fixed here, but worth noting.

## Final Report

Development completed as planned.
