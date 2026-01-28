---
created_at: 2026-01-29T01:58:17+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: cc9812e
category: Added
---

# Add discover-history Subagent for Finding Related Tickets

## Overview

Create a `discover-history` skill with a shell script that searches `.workaholic/tickets/archive/` by multiple keywords, plus a haiku subagent (`history-discoverer`) that uses this skill to find related historical tickets. The `/ticket` command will invoke this subagent to populate the Related History section, offloading the search work to a fast, cheap agent.

## Key Files

- `plugins/core/skills/discover-history/SKILL.md` - New skill with search instructions
- `plugins/core/skills/discover-history/sh/search.sh` - Shell script for multi-keyword grep
- `plugins/core/agents/history-discoverer.md` - New haiku subagent
- `plugins/core/commands/ticket.md` - Invoke history-discoverer subagent
- `plugins/core/skills/create-ticket/SKILL.md` - Remove inline "Finding Related History" section (moved to skill)

## Related History

The Related History feature was added to provide context about past work. Currently, the search logic is inline in the create-ticket skill.

Past tickets that touched similar areas:

- [20260127101903-add-related-history-to-tickets.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101903-add-related-history-to-tickets.md) - Added Related History section (original implementation)
- [20260127202525-add-related-history-summary.md](.workaholic/tickets/archive/feat-20260126-214833/20260127202525-add-related-history-summary.md) - Added summary synthesis
- [20260128005204-link-archived-tickets-in-related-history.md](.workaholic/tickets/archive/feat-20260128-001720/20260128005204-link-archived-tickets-in-related-history.md) - Added markdown links

## Implementation Steps

1. Create `plugins/core/skills/discover-history/sh/search.sh`:
   ```bash
   #!/bin/sh -eu
   # Search archived tickets by multiple keywords
   # Usage: search.sh <keyword1> [keyword2] [keyword3] ...
   # Output: List of matching ticket paths with match counts

   set -eu

   if [ $# -eq 0 ]; then
       echo "Usage: search.sh <keyword1> [keyword2] ..."
       exit 1
   fi

   ARCHIVE_DIR=".workaholic/tickets/archive"

   # Build grep pattern: keyword1|keyword2|keyword3
   PATTERN=$(echo "$@" | tr ' ' '|')

   # Search and count matches per file, sort by count descending
   grep -rilE "$PATTERN" "$ARCHIVE_DIR" 2>/dev/null | while read -r file; do
       count=$(grep -ciE "$PATTERN" "$file" 2>/dev/null || echo 0)
       echo "$count $file"
   done | sort -rn | head -20
   ```

2. Create `plugins/core/skills/discover-history/SKILL.md`:
   ```markdown
   ---
   name: discover-history
   description: Search archived tickets by keywords to find related historical context.
   allowed-tools: Bash
   user-invocable: false
   ---

   # Discover History

   Search archived tickets to find related past work.

   ## Instructions

   Run the bundled script with keywords extracted from the ticket request:

   ```bash
   bash .claude/skills/discover-history/sh/search.sh <keyword1> [keyword2] ...
   ```

   ### Keyword Extraction

   Extract 3-5 keywords from:
   - Key file paths (e.g., `ticket.md`, `drive.md`)
   - Domain terms (e.g., `branch`, `commit`, `archive`)
   - Layer names (e.g., `Config`, `UX`)

   ### Output Format

   The script returns matches sorted by relevance (match count):

   ```
   5 .workaholic/tickets/archive/feat-xxx/ticket-a.md
   3 .workaholic/tickets/archive/feat-yyy/ticket-b.md
   ```

   ### Interpreting Results

   - Higher count = more keyword matches = more relevant
   - Read top 5 tickets to understand context
   - Extract: title, overview, key files, layer
   ```

3. Create `plugins/core/agents/history-discoverer.md`:
   ```markdown
   ---
   name: history-discoverer
   description: Find related historical tickets using keyword search.
   tools: Bash, Read, Glob
   skills:
     - discover-history
   ---

   # History Discoverer

   Search archived tickets to find related historical context for a new ticket.

   ## Input

   You will receive:
   - Keywords to search for (file paths, domain terms)
   - Optional: Layer to filter by

   ## Instructions

   1. Run the discover-history search script with provided keywords
   2. Read the top 5 matching tickets
   3. For each, extract: title, overview summary, key files, layer
   4. Return a structured list sorted by relevance

   ## Output

   Return JSON:

   ```json
   {
     "summary": "1-2 sentence synthesis of what historical tickets reveal",
     "tickets": [
       {
         "path": ".workaholic/tickets/archive/feat-xxx/filename.md",
         "title": "Ticket title",
         "overview": "Brief 1-sentence summary",
         "match_reason": "same file: ticket.md"
       }
     ]
   }
   ```
   ```

4. Update `plugins/core/commands/ticket.md`:
   - Add `history-discoverer` subagent invocation before writing ticket
   - Pass keywords: key file basenames + domain terms from user request
   - Use `model: "haiku"` for fast, cheap execution
   - Insert returned tickets into Related History section

5. Update `plugins/core/skills/create-ticket/SKILL.md`:
   - Remove the "Finding Related History" section (lines 110-130)
   - Add note that Related History is populated by history-discoverer subagent
   - Keep the Related History template in the file structure section

## Considerations

- Using haiku model keeps cost low for this exploratory task
- Shell script handles the heavy lifting (grep), subagent does synthesis
- Keywords should be specific: file basenames work better than full paths
- The subagent returns JSON for easy parsing by ticket command
- Falls back gracefully if no matches found (empty tickets array)

## Final Report

Development completed as planned.
