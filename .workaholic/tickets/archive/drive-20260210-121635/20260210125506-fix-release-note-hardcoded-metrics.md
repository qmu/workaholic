---
created_at: 2026-02-10T12:55:06+08:00
author: a@qmu.jp
type: bugfix
layer: [Domain, Config]
effort: 0.1h
commit_hash: 02f6c18
category:
---

# Fix Release Note Hardcoded Metrics

## Overview

The release-note-writer subagent produces metrics that sometimes match the hardcoded example values from the original implementation ticket ("Tickets Completed: 8, Commits: 24, Duration: 2 days (27 hours)") rather than extracting actual metrics from the story file frontmatter. The root cause is twofold: (1) the write-release-note skill lacks explicit instructions to substitute actual frontmatter values and uses a vague `N` placeholder format, and (2) the release-note-writer agent output example contains concrete numeric values (`tickets_completed: 6, commits: 12, duration_hours: 1.0`) that a small model (haiku) may treat as defaults. Additionally, the skill template only references `duration_hours` while story frontmatter also includes `duration_days`, causing inconsistent duration formatting across release notes.

## Key Files

- `plugins/core/skills/write-release-note/SKILL.md` - Skill template with vague metrics placeholders and missing `duration_days` reference
- `plugins/core/agents/release-note-writer.md` - Agent with concrete numeric example values in output JSON
- `.workaholic/stories/drive-20260204-160722.md` - Story with frontmatter metrics (source of the "8/24/27" values that get replicated)
- `.workaholic/release-notes/drive-20260204-160722.md` - First release note that matched the story (establishing the pattern the model copies)

## Related History

The release-note-writer was added in drive-20260204-160722 as a subagent invoked during Phase 4 of the story-writer workflow. The original ticket contained concrete example values in the output JSON that propagated into the agent definition, creating a subtle template for the model to copy rather than compute.

Past tickets that touched similar areas:

- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Created release-note-writer and write-release-note skill (same files)
- [20260131192343-fix-write-story-performance-analyst-invocation.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192343-fix-write-story-performance-analyst-invocation.md) - Fixed metric extraction from performance-analyst (same pattern: metrics pipeline)
- [20260128002346-integrate-calculate-story-metrics-into-write-story.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002346-integrate-calculate-story-metrics-into-write-story.md) - Integrated metrics calculation into story writing (upstream dependency)

## Implementation Steps

1. **Update write-release-note skill** (`plugins/core/skills/write-release-note/SKILL.md`):
   - Replace vague `N` placeholders in template with explicit `<tickets_completed>`, `<commits>`, `<duration>` substitution markers
   - Add `duration_days` to the list of frontmatter fields to extract
   - Define a clear duration formatting rule: use `duration_days` + `duration_hours` together (e.g., "2 days (27.2 hours)") when both are available, fall back to hours only
   - Add an explicit warning: "Never use example or placeholder values -- always extract from the story frontmatter"

2. **Update release-note-writer agent** (`plugins/core/agents/release-note-writer.md`):
   - Replace concrete numeric values in the output JSON example with descriptive placeholders (e.g., `<actual_count>`) to prevent model from treating them as defaults
   - Add explicit instruction to verify extracted metrics against the story frontmatter before writing

## Patches

### `plugins/core/skills/write-release-note/SKILL.md`

```diff
--- a/plugins/core/skills/write-release-note/SKILL.md
+++ b/plugins/core/skills/write-release-note/SKILL.md
@@ -11,13 +11,13 @@
 ```markdown
 ## Summary

-[2-3 sentence overview extracted from story section 1]
+<2-3 sentence overview extracted from story section 1>

 ## Key Changes

-- [Highlight 1 from story]
-- [Highlight 2 from story]
-- [Highlight 3 from story]
+- <Highlight 1 from story>
+- <Highlight 2 from story>
+- <Highlight 3 from story>

 ## Metrics

@@ -25,8 +25,8 @@
-- **Tickets Completed**: N
-- **Commits**: N
-- **Duration**: N hours
+- **Tickets Completed**: <tickets_completed from frontmatter>
+- **Commits**: <commits from frontmatter>
+- **Duration**: <duration_days from frontmatter> days (<duration_hours from frontmatter> hours)

 ## Links

@@ -38,9 +38,11 @@

 3. **Metrics**: Extract from story frontmatter:
    - `tickets_completed` field
    - `commits` field
-   - `duration_hours` field (round to 1 decimal)
+   - `duration_hours` field (round to 1 decimal place)
+   - `duration_days` field (use when available)
+   - Format duration as: "N days (N hours)" when both fields exist, "N hours" when only hours exist

 4. **Links**: Include absolute GitHub URLs when available.
```

### `plugins/core/agents/release-note-writer.md`

```diff
--- a/plugins/core/agents/release-note-writer.md
+++ b/plugins/core/agents/release-note-writer.md
@@ -20,7 +20,7 @@

 Extract:
 - Overview from section 1
 - Highlights from section 1
-- Frontmatter metrics (tickets_completed, commits, duration_hours)
+- Frontmatter metrics (tickets_completed, commits, duration_hours, duration_days)

 ### Step 2: Generate Release Note

@@ -30,6 +30,8 @@
 - Summary (2-3 sentences from Overview)
 - Key Changes (highlights as bullet points)
 - Metrics (from frontmatter)
+  - **Important**: Always use the actual numeric values from the story frontmatter. Never use example or placeholder values.
+  - Format duration using both `duration_days` and `duration_hours` when available.
 - Links (PR URL if available, story file path)

 ### Step 3: Write Release Note File
@@ -52,9 +54,9 @@
 {
   "release_note_file": ".workaholic/release-notes/<branch-name>.md",
   "summary": "Brief one-line summary",
   "metrics": {
-    "tickets_completed": 6,
-    "commits": 12,
-    "duration_hours": 1.0
+    "tickets_completed": "<actual value from story frontmatter>",
+    "commits": "<actual value from story frontmatter>",
+    "duration_hours": "<actual value from story frontmatter>"
   }
 }
 ```
```

## Considerations

- The release-note-writer is invoked with `model: "haiku"` (`plugins/core/agents/story-writer.md` line 49), which is a smaller model more susceptible to echoing example values rather than performing extraction. If the bug persists after this fix, consider upgrading to a larger model or adding a validation step.
- The `duration_days` field is only present in story frontmatter when `velocity_unit` is `"day"` (`plugins/core/skills/write-story/SKILL.md` line 211), so the duration formatting rule must handle its absence gracefully.
- The output JSON example in `release-note-writer.md` uses concrete numbers that serve as implicit defaults for the model. Replacing them with string placeholders changes the JSON schema from numeric to string, which is acceptable since this is documentation for the model, not a parsed contract.
- Existing release notes in `.workaholic/release-notes/` will not be retroactively fixed -- this only affects future invocations.

## Final Report

All patches applied exactly as specified. Two files modified:

- **write-release-note SKILL.md**: Replaced bracket and `N` placeholders with explicit `<field from frontmatter>` markers. Added `duration_days` field and formatting rule for graceful fallback.
- **release-note-writer.md**: Added `duration_days` to extraction list, added explicit warning against placeholder values, replaced hardcoded numeric example values (6, 12, 1.0) with descriptive string placeholders.

No deviations from the ticket plan.
