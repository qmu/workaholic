---
created_at: 2026-03-29T17:36:05+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash: 1811c2f
category: Changed
---

# Restructure Story Template: Remove Performance and Merge Journey into Changes

## Overview

Simplify the story template from 11 sections to 9 by removing section 9 (Performance) entirely and merging section 3 (Journey) into section 4 (Changes). The Performance section -- metrics, pace analysis, and the five-dimension decision review table (Consistency, Intuitivity, Describability, Agility, Density) -- adds complexity without proportional value. The Journey section (Mermaid flowchart and summary) is conceptually part of the Changes narrative and should live there. This also removes the performance-analyst agent invocation from the story-writer agent, reducing parallel agent calls from 4 to 3 and eliminating the dependency on the analyze-performance skill and its calculate.sh script.

## Key Files

- `plugins/drivin/skills/write-story/SKILL.md` - Story content structure template; remove section 9 (Performance), merge section 3 (Journey) into section 4 (Changes), renumber sections 5-11 to 4-9, update Agent Output Mapping table, remove performance-analyst frontmatter references
- `plugins/drivin/agents/story-writer.md` - Story writer orchestration; remove performance-analyst from the 4 parallel agent invocations (reduce to 3), remove performance_analyst from output JSON agents map
- `plugins/standards/agents/performance-analyst.md` - Performance analyst subagent; no longer invoked by story-writer (may become unused)
- `plugins/standards/skills/analyze-performance/SKILL.md` - Performance analysis evaluation framework; no longer needed by story-writer (may become unused)
- `plugins/standards/skills/analyze-performance/sh/calculate.sh` - Metrics calculation script; no longer needed by story-writer
- `plugins/standards/agents/overview-writer.md` - Overview writer; still produces `journey.mermaid` and `journey.summary` but these now map to the merged Changes section instead of a standalone Journey section

## Related History

The story template has been iteratively simplified over time, with agents being removed or consolidated and sections being streamlined for conciseness.

Past tickets that touched similar areas:

- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/archive/drive-20260202-134332/20260202200553-reorganize-story-agent-hierarchy.md) - Restructured story-writer as central orchestration hub with parallel subagent invocation (same file: story-writer.md)
- [20260204172657-remove-translator-from-story-writer.md](.workaholic/tickets/archive/drive-20260204-160722/20260204172657-remove-translator-from-story-writer.md) - Removed translation responsibility from story-writer to simplify its scope (same pattern: removing agent responsibility)
- [20260210121628-summarize-changes-in-report.md](.workaholic/tickets/archive/drive-20260210-121635/20260210121628-summarize-changes-in-report.md) - Simplified Changes section from per-file listings to concise summaries (same file: write-story/SKILL.md)
- [20260328152057-create-standards-plugin.md](.workaholic/tickets/archive/drive-20260326-183949/20260328152057-create-standards-plugin.md) - Moved performance-analyst, overview-writer, section-reviewer to standards plugin (same agents being modified)

## Implementation Steps

1. **Update write-story skill** (`plugins/drivin/skills/write-story/SKILL.md`):
   - Remove the Agent Output Mapping row for performance-analyst (section 9)
   - Update overview-writer row: sections column changes from `1, 2, 3` to `1, 2` (journey fields move to Changes section)
   - Add note that overview-writer `journey.mermaid` and `journey.summary` are used in the Changes section preamble
   - Update "Section 4 comes from archived tickets" note to mention journey content is also included
   - Remove section 3 (Journey) as a standalone section -- its content (Mermaid flowchart and summary) becomes a preamble to section 3 (Changes, previously section 4)
   - Remove section 9 (Performance) entirely -- all metrics, pace analysis, and decision review table
   - Remove the "Performance-analyst input" explanatory paragraph
   - Renumber remaining sections: Overview (1), Motivation (2), Changes (3, now includes journey), Outcome (4), Historical Analysis (5), Concerns (6), Ideas (7), Release Preparation (8), Notes (9)
   - Update Story Frontmatter to remove performance-analyst metric fields (`started_at`, `ended_at`, `commits`, `duration_hours`, `duration_days`, `velocity`, `velocity_unit`) since those came from performance-analyst output
   - Keep `branch` and `tickets_completed` in frontmatter

2. **Update story-writer agent** (`plugins/drivin/agents/story-writer.md`):
   - Change Phase 1 from "4 agents in parallel" to "3 agents in parallel"
   - Remove the performance-analyst Task invocation line
   - Remove `performance_analyst` from the output JSON agents map
   - Update any references to "4 agents" in Phase 2 prose

3. **Verify overview-writer** (`plugins/standards/agents/overview-writer.md`):
   - No changes needed to the agent itself; it still produces `journey.mermaid` and `journey.summary` in its JSON output
   - The story-writer will now place this journey content into the Changes section preamble instead of a standalone section

## Patches

### `plugins/drivin/agents/story-writer.md`

```diff
--- a/plugins/drivin/agents/story-writer.md
+++ b/plugins/drivin/agents/story-writer.md
@@ -19,11 +19,10 @@

 ### Phase 1: Invoke Story Generation Agents

-Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):
+Invoke 3 agents in parallel via Task tool (single message with 3 tool calls):

 - **release-readiness** (`subagent_type: "drivin:release-readiness"`, `model: "opus"`): Analyzes branch for release readiness. Pass archived tickets list and branch name.
-- **performance-analyst** (`subagent_type: "standards:performance-analyst"`, `model: "opus"`): Evaluates decision quality. Pass archived tickets list and git log.
 - **overview-writer** (`subagent_type: "standards:overview-writer"`, `model: "opus"`): Generates overview, highlights, motivation, and journey. Pass branch name and base branch.
 - **section-reviewer** (`subagent_type: "standards:section-reviewer"`, `model: "opus"`): Generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas). Pass branch name and archived tickets list.

-Wait for all 4 agents to complete. Track which succeeded and which failed.
+Wait for all 3 agents to complete. Track which succeeded and which failed.
```

```diff
--- a/plugins/drivin/agents/story-writer.md
+++ b/plugins/drivin/agents/story-writer.md
@@ -64,7 +63,6 @@
   "agents": {
     "overview_writer": { "status": "success" | "failed", "error": "..." },
     "section_reviewer": { "status": "success" | "failed", "error": "..." },
     "release_readiness": { "status": "success" | "failed", "error": "..." },
-    "performance_analyst": { "status": "success" | "failed", "error": "..." },
     "release_note_writer": { "status": "success" | "failed", "error": "..." },
     "pr_creator": { "status": "success" | "failed", "error": "..." }
   }
```

### `plugins/drivin/skills/write-story/SKILL.md`

> **Note**: These patches are speculative due to the large scope of section renumbering. Verify exact content and line numbers before applying.

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -13,11 +13,10 @@
 | Agent | Sections | Fields |
 | ----- | -------- | ------ |
-| overview-writer | 1, 2, 3 | `overview`, `highlights[]`, `motivation`, `journey.mermaid`, `journey.summary` |
-| section-reviewer | 5, 6, 7, 8 | `outcome`, `historical_analysis`, `concerns`, `ideas` |
-| performance-analyst | 9 | metrics JSON + decision review markdown |
-| release-readiness | 10 | `verdict`, `concerns[]`, `instructions.pre_release[]`, `instructions.post_release[]` |
+| overview-writer | 1, 2, 3 (journey preamble) | `overview`, `highlights[]`, `motivation`, `journey.mermaid`, `journey.summary` |
+| section-reviewer | 4, 5, 6, 7 | `outcome`, `historical_analysis`, `concerns`, `ideas` |
+| release-readiness | 8 | `verdict`, `concerns[]`, `instructions.pre_release[]`, `instructions.post_release[]` |
 | release-note-writer | (separate file) | Writes to `.workaholic/release-notes/<branch>.md` |

-Section 4 (Changes) comes from archived tickets. Section 11 (Notes) is optional context.
+Section 3 (Changes) comes from archived tickets, prefaced by journey content from overview-writer. Section 9 (Notes) is optional context.
```

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -42,36 +41,7 @@

 ## 2. Motivation

 [Content from overview-writer `motivation` field: paragraph synthesizing the "why" from commit context.]

-## 3. Journey
-
-```mermaid
-flowchart LR
-  subgraph Subagents[Subagent Architecture]
-    direction TB
-    s1[Extract spec-writer] --> s2[Extract story-writer] --> s3[Extract changelog-writer] --> s4[Extract pr-creator]
-  end
-
-  subgraph GitSafety[Git Command Safety]
-    direction TB
-    g1[Add git guidelines] --> g2[Strengthen rules] --> g3[Embed in agents] --> g4[Use deny rule]
-  end
-
-  subgraph Commands[Command Simplification]
-    direction TB
-    c1[Remove /sync] --> c2[Remove /commit] --> c3[Unify to /report]
-  end
-
-  Subagents --> GitSafety --> Commands
-```
-
-**Flowchart Guidelines:**
-- Use `flowchart LR` for horizontal timeline (subgraphs arranged left-to-right)
-- Use `direction TB` inside each subgraph for vertical item flow
-- Group by theme: each subgraph represents one concern or decision area
-- Connect subgraphs in timeline order to show work progression
-- Use descriptive node labels: `id[Description]` syntax
-- Maximum 3-5 subgraphs per diagram
-
-[Content from overview-writer `journey.mermaid` for the flowchart and `journey.summary` for this prose section.]
-
-## 4. Changes
+## 3. Changes

 One subsection per ticket, in chronological order:
+
+**Journey:**
+
+```mermaid
+[Content from overview-writer `journey.mermaid`]
+```
+
+[Content from overview-writer `journey.summary`]
+
+**Flowchart Guidelines:**
+- Use `flowchart LR` for horizontal timeline (subgraphs arranged left-to-right)
+- Use `direction TB` inside each subgraph for vertical item flow
+- Group by theme: each subgraph represents one concern or decision area
+- Connect subgraphs in timeline order to show work progression
+- Use descriptive node labels: `id[Description]` syntax
+- Maximum 3-5 subgraphs per diagram
```

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -98,9 +78,9 @@

-## 5. Outcome
+## 4. Outcome

-## 6. Historical Analysis
+## 5. Historical Analysis

-## 7. Concerns
+## 6. Concerns

-## 8. Ideas
+## 7. Ideas
```

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -126,37 +106,1 @@

-## 9. Performance
-
-**Metrics**: <commits> commits over <duration> <unit> (<velocity> commits/<unit>)
-
-### 9-1. Pace Analysis
-
-[Quantitative reflection on development pace - was velocity consistent or varied? Were commits small and focused or large? Any patterns in timing?]
-
-### 9-2. Decision Review
-
-| Dimension      | Rating                            | Notes             |
-| -------------- | --------------------------------- | ----------------- |
-| Consistency    | Strong/Adequate/Needs Improvement | Brief observation |
-| Intuitivity    | ...                               | ...               |
-| Describability | ...                               | ...               |
-| Agility        | ...                               | ...               |
-| Density        | ...                               | ...               |
-
-**Strengths**: [Key positive patterns observed]
-
-**Areas for Improvement**: [Constructive suggestions]
-```
-
-**Performance-analyst input:**
-
-The performance-analyst output (metrics JSON and decision review markdown) is provided by story-writer which invokes performance-analyst as a parallel agent. Include the complete output in section 9.
-
-```markdown
-## 10. Release Preparation
+## 8. Release Preparation
```

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -190,7 +135,7 @@

-## 11. Notes
+## 9. Notes

 Additional context for reviewers or future reference.
```

```diff
--- a/plugins/drivin/skills/write-story/SKILL.md
+++ b/plugins/drivin/skills/write-story/SKILL.md
@@ -199,14 +144,8 @@

 ```yaml
 ---
 branch: <branch-name>
-started_at: <from performance-analyst metrics>
-ended_at: <from performance-analyst metrics>
 tickets_completed: <count of tickets>
-commits: <from performance-analyst metrics>
-duration_hours: <from performance-analyst metrics>
-duration_days: <from performance-analyst metrics if velocity_unit is "day">
-velocity: <from performance-analyst metrics>
-velocity_unit: <from performance-analyst metrics>
 ---
 ```
```

## Considerations

- The performance-analyst agent (`plugins/standards/agents/performance-analyst.md`) and analyze-performance skill (`plugins/standards/skills/analyze-performance/SKILL.md`) are no longer invoked by story-writer after this change. They may still be used by other workflows (e.g., `/scan`). Verify whether they have other callers before considering removal. (`plugins/standards/agents/performance-analyst.md`)
- The story frontmatter loses most of its metric fields (`started_at`, `ended_at`, `commits`, `duration_hours`, `duration_days`, `velocity`, `velocity_unit`). Any downstream consumers that read story frontmatter for metrics will break. Check if any scripts or tools parse these fields. (`plugins/drivin/skills/write-story/SKILL.md` lines 199-215)
- The section-reviewer agent description says "Generate story sections 5-8" -- after renumbering these become sections 4-7. The section-reviewer agent and its review-sections skill may reference section numbers that need updating. (`plugins/standards/agents/section-reviewer.md`)
- The Changes subsection numbering format changes from `4-N` to `3-N`. The Changes Guidelines in write-story skill reference this format and must be updated. (`plugins/drivin/skills/write-story/SKILL.md` lines 80-98)
- Existing stories in `.workaholic/stories/` use the 11-section format. New stories will use the 9-section format. This creates a format inconsistency in the archive but is acceptable since stories are point-in-time documents. (`.workaholic/stories/`)
- The journey content (Mermaid flowchart) placed as a preamble to Changes could make the Changes section longer. Consider whether the flowchart should come before or after the per-ticket subsections. (`plugins/drivin/skills/write-story/SKILL.md`)
