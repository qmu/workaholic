---
created_at: 2026-02-03T19:05:11+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 4306539
category: Changed
---

# Fix Memory Leak in /ticket Command

## Overview

Add hard limits to archive search, source exploration, and response aggregation in the /ticket command workflow to prevent memory exhaustion. The current implementation has unbounded operations that can accumulate excessive context: the history-discoverer grep runs across 200+ archived tickets without limits, the source-discoverer has no enforced file count limits (20-30 is just a guideline), and the ticket-organizer aggregates full contents from 3 parallel subagents without truncation.

## Key Files

- `plugins/core/skills/discover-history/sh/search.sh` - Add --max-count limit to grep
- `plugins/core/skills/discover-history/SKILL.md` - Document file read length limits
- `plugins/core/agents/history-discoverer.md` - Enforce truncation when reading tickets
- `plugins/core/skills/discover-source/SKILL.md` - Convert budget from guideline to hard limit
- `plugins/core/agents/source-discoverer.md` - Enforce file count and snippet size limits
- `plugins/core/agents/ticket-organizer.md` - Document expected summary format from subagents

## Related History

The /ticket command's discovery subagents were enhanced for richer context collection (parallel invocation, deeper source exploration), but no corresponding memory safeguards were added. The original nesting policy warned about "context explosion" but the implemented limits are soft guidelines.

Past tickets that touched similar areas:

- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Introduced 3 parallel subagents without output size limits (root cause)
- [20260202183250-enhance-source-discoverer-depth.md](.workaholic/tickets/archive/drive-20260202-134332/20260202183250-enhance-source-discoverer-depth.md) - Added 5-phase exploration with soft 20-30 file budget (guideline not enforced)
- [20260129015817-add-discover-history-subagent.md](.workaholic/tickets/archive/feat-20260128-220712/20260129015817-add-discover-history-subagent.md) - Original history discoverer (no grep limits)

## Implementation Steps

1. **Add --max-count limit to discover-history search.sh**
   - Add `-m 10` (--max-count) to the inner grep to limit matches per file
   - Add `head -10` at the end to limit to top 10 matching files (currently head -20)
   - This bounds the worst-case to 10 files with 10 matches each = 100 lines of context

2. **Add file read length limits to history-discoverer**
   - Read only the first 100 lines of each matched ticket using Read tool with `limit: 100`
   - Update instructions to specify: "Read the top 5 matching tickets (first 100 lines each)"
   - This bounds ticket content to ~5 * 100 = 500 lines max

3. **Enforce hard file limits in discover-source skill**
   - Change "Target 20-30 files" to "Hard limit: 20 files total"
   - Add explicit stop after 20 files: "Stop exploration after reaching 20 files regardless of phase"
   - Add per-phase hard limits: Phase 1 (8), Phase 2 (6), Phase 3 (3), Phase 4 (2), Phase 5 (1)

4. **Add snippet truncation in source-discoverer**
   - Limit code snippets to first 30 lines each
   - Limit to max 5 snippets total in output
   - Add to output format: "snippets (max 5, each max 30 lines)"

5. **Document subagent output expectations in ticket-organizer**
   - Add note that subagents return summaries, not full file contents
   - Specify expected output size: "Each subagent JSON response should be under 200 lines"
   - Ticket-organizer synthesizes summaries, does not re-read files

## Patches

### `plugins/core/skills/discover-history/sh/search.sh`

```diff
--- a/plugins/core/skills/discover-history/sh/search.sh
+++ b/plugins/core/skills/discover-history/sh/search.sh
@@ -16,8 +16,8 @@ ARCHIVE_DIR=".workaholic/tickets/archive"
 PATTERN=$(echo "$@" | tr ' ' '|')

 # Search and count matches per file, sort by count descending
-grep -rilE "$PATTERN" "$ARCHIVE_DIR" 2>/dev/null | while read -r file; do
-    count=$(grep -ciE "$PATTERN" "$file" 2>/dev/null || echo 0)
+grep -rilE -m 10 "$PATTERN" "$ARCHIVE_DIR" 2>/dev/null | while read -r file; do
+    count=$(grep -ciE -m 10 "$PATTERN" "$file" 2>/dev/null || echo 0)
     echo "$count $file"
-done | sort -rn | head -20
+done | sort -rn | head -10
```

### `plugins/core/agents/history-discoverer.md`

```diff
--- a/plugins/core/agents/history-discoverer.md
+++ b/plugins/core/agents/history-discoverer.md
@@ -17,7 +17,9 @@ You will receive:
 ## Instructions

 1. Run the discover-history search script with provided keywords
-2. Read the top 5 matching tickets
+2. Read the top 5 matching tickets (use Read tool with `limit: 100` to read only first 100 lines each)
 3. For each, extract: title, overview summary, key files, layer
 4. Return a structured list sorted by relevance
+
+**Memory limit**: Total output JSON should be under 200 lines. Return summaries, not full ticket contents.
```

### `plugins/core/skills/discover-source/SKILL.md`

```diff
--- a/plugins/core/skills/discover-source/SKILL.md
+++ b/plugins/core/skills/discover-source/SKILL.md
@@ -54,10 +54,12 @@ Find related configuration and type definitions.

 ## Depth Controls

-- **Max files per phase**: Limit each phase to recommended file counts above
+- **Hard limits per phase**: Phase 1 (8 files), Phase 2 (6), Phase 3 (3), Phase 4 (2), Phase 5 (1)
 - **Relevance scoring**: Prioritize files with higher keyword density
 - **Stop conditions**: Stop following chains when files become tangential
-- **Total budget**: Target 20-30 files total across all phases
+- **Total budget**: Hard limit of 20 files total - stop exploration immediately upon reaching limit
 - **Time budget**: Complete exploration within 30 seconds
+
+**Important**: These are hard limits, not guidelines. Stop adding files once limits are reached.
```

### `plugins/core/agents/source-discoverer.md`

```diff
--- a/plugins/core/agents/source-discoverer.md
+++ b/plugins/core/agents/source-discoverer.md
@@ -30,11 +30,13 @@ For each phase:
 - Use appropriate tools (Glob, Grep, Read)
 - Score relevance and skip tangential files
 - Collect code snippets that illustrate patterns
-- **Capture snippets** from sections likely to need modification (include start/end line numbers)
-- Stay within total budget of 20-30 files
+- **Capture snippets** from sections likely to need modification (max 30 lines each, max 5 snippets total)
+- **Hard limit**: Stop at 20 files total regardless of which phase

 ## Output

+**Memory limit**: Total output JSON should be under 200 lines.
+
 Return JSON with categorized discoveries:

 ```json
@@ -52,7 +54,7 @@ Return JSON with categorized discoveries:
   "snippets": [
     {
       "path": "path/to/file.ts",
-      "start_line": 10,
+      "start_line": 10,  // max 30 lines per snippet
       "end_line": 25,
       "content": "actual code content that may need modification"
     }
```

### `plugins/core/agents/ticket-organizer.md`

```diff
--- a/plugins/core/agents/ticket-organizer.md
+++ b/plugins/core/agents/ticket-organizer.md
@@ -46,6 +46,8 @@ Invoke ALL THREE subagents concurrently using Task tool (single message with thr

 Wait for all three to complete, then proceed with all JSON results.

+**Note**: Subagents return summarized JSON (under 200 lines each), not full file contents. The ticket-organizer synthesizes these summaries rather than re-reading source files.
+
 ### 3. Handle Moderation Result
```

## Considerations

- **Backward compatibility**: These are internal limits that don't change the external interface
- **Information loss**: Stricter limits may miss some relevant context, but prevents system from becoming unusable
- **Tuning**: The specific numbers (10 files, 100 lines, 20 files, 30 lines) may need adjustment based on real-world usage
- **Monitoring**: Consider adding logging to track when limits are hit, to inform future tuning
- **Architectural alternative**: A more robust solution would implement streaming/pagination, but hard limits are simpler to implement and maintain

## Final Report

Applied all patches as specified. Added `-m 10` to grep commands in search.sh and reduced output to top 10 files. Updated history-discoverer with 100-line read limits and 200-line JSON output limit. Converted discover-source soft budget to hard limits (20 files total, per-phase limits). Added snippet constraints (max 30 lines, max 5 snippets) to source-discoverer. Documented subagent JSON size expectations in ticket-organizer.
