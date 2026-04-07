---
created_at: 2026-04-07T15:48:35+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 5d6438f
category: Changed
---

# Refactor Discoverer: Merge History+Ticket Modes, Add Policy Mode

## Overview

Refactor the Discoverer agent's three modes (history, source, ticket) into a new set of three modes: history (merged with ticket), source (unchanged), and policy (new). The History mode currently only searches archived tickets; it should also search todo and icebox tickets, absorbing the Ticket mode's duplicate/overlap detection responsibilities. A new Policy mode discovers repository standards, coding conventions, design decisions, and architecture patterns to provide evidence for how the repository concretizes its standards.

## Key Files

- `plugins/work/agents/discoverer.md` - Parameterized discoverer agent; mode routing table must change from history/source/ticket to history/source/policy
- `plugins/work/skills/discover/SKILL.md` - Core skill with three sections (Discover History, Discover Source, Discover Ticket); Discover History must expand, Discover Ticket must be removed, Discover Policy must be added
- `plugins/work/skills/discover/scripts/search.sh` - Search script currently only searches archive directory; must also search todo and icebox
- `plugins/work/agents/ticket-organizer.md` - Orchestrator that invokes three discoverers in parallel; must update mode names and handle merged history+ticket output
- `plugins/work/skills/create-ticket/SKILL.md` - References discoverer agent in history mode for Related History section; may need updates for merged output format
- `plugins/work/README.md` - Documents discoverer as "history, source, ticket modes"; must update to "history, source, policy modes"

## Related History

The discoverer architecture was recently consolidated from three separate agent files into a single parameterized agent, and the codebase has strong precedent for this kind of structural refactoring. The current ticket mode and history mode were created as parallel discovery phases.

- [20260406185951-consolidate-discoverer-agents.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406185951-consolidate-discoverer-agents.md) - Consolidated 3 discoverer agents into single parameterized discoverer.md (the exact agent being refactored here)
- [20260406182846-consolidate-lead-agents-into-parameterized-agent.md](.workaholic/tickets/archive/work-20260404-101424-fix-trip-report-dir-path/20260406182846-consolidate-lead-agents-into-parameterized-agent.md) - Consolidated 10 lead agents into single parameterized lead.md (same consolidation pattern, precedent for skill-heavy refactoring)

## Implementation Steps

1. **Expand `search.sh` to search todo and icebox in addition to archive**

   The script currently only searches `.workaholic/tickets/archive`. Add `.workaholic/tickets/todo` and `.workaholic/tickets/icebox` to the search scope. The output format remains the same (count + path, sorted by relevance).

2. **Merge Discover Ticket into Discover History in `SKILL.md`**

   Expand the "Discover History" section to include the ticket overlap analysis responsibilities currently in "Discover Ticket":
   - After searching and reading historical tickets, also search todo and icebox directories
   - Perform the overlap analysis (duplicate detection, merge candidates, split candidates, related tickets) that currently lives in the "Discover Ticket" section
   - The output schema must be a union: include the existing history fields (`summary`, `tickets` array with paths and match reasons) plus the ticket moderation fields (`status`, `matches`, `recommendation`)

   Remove the "Discover Ticket" section entirely since its responsibilities are now in Discover History.

3. **Add "Discover Policy" section to `SKILL.md`**

   Create a new section after Discover Source with instructions for the policy discovery mode:
   - **Search locations**: CLAUDE.md, `.claude/rules/`, plugin rules directories, README files, configuration files (tsconfig, eslint, prettier, etc.), and any `standards/` plugin content
   - **Discovery categories**:
     - Coding conventions (naming, formatting, patterns)
     - Architecture decisions (component nesting rules, plugin dependencies, design principles)
     - Shell script policies (extraction rules, path rules)
     - Documentation standards
   - **Output schema**: JSON with `summary`, `policies` array (each with `category`, `source_file`, `description`, `evidence`), and `architecture` object describing the repository's structural patterns

4. **Update `discoverer.md` mode routing table**

   Change the three modes from history/source/ticket to history/source/policy:

   | Mode | Skill Section | Purpose |
   | ---- | ------------- | ------- |
   | `history` | Discover History | Search all tickets (archive, todo, icebox) for related work and check for duplicates |
   | `source` | Discover Source | Explore codebase for relevant files and code flow |
   | `policy` | Discover Policy | Identify repository standards, conventions, and architecture |

5. **Update `ticket-organizer.md` parallel discovery**

   Change the three parallel discoverer invocations:
   - **discoverer (history)**: Now returns both history context AND ticket moderation result (status/matches/recommendation)
   - **discoverer (source)**: Unchanged
   - **discoverer (policy)**: New third mode replacing ticket mode; returns standards/conventions context

   Update section 3 (Handle Moderation Result) to read the moderation status from the history discoverer's output instead of a separate ticket discoverer.

   Update section 5 (Write Tickets) to use policy discovery output for informing implementation guidance (conventions to follow, architecture patterns to respect).

6. **Update `create-ticket/SKILL.md` references**

   The Related History section reference remains valid since the discoverer in history mode still populates it. If the merged output format changes field names, update the reference accordingly.

7. **Update `README.md` discoverer description**

   Change "Context discovery (history, source, ticket modes)" to "Context discovery (history, source, policy modes)".

## Patches

### `plugins/work/skills/discover/scripts/search.sh`

```diff
--- a/plugins/work/skills/discover/scripts/search.sh
+++ b/plugins/work/skills/discover/scripts/search.sh
@@ -11,10 +11,16 @@ fi
 
 ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
 
-ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive"
+ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive"
+TODO_DIR="${ROOT}/.workaholic/tickets/todo"
+ICEBOX_DIR="${ROOT}/.workaholic/tickets/icebox"
+
+# Collect all search directories that exist
+SEARCH_DIRS=""
+for dir in "$ARCHIVE_DIR" "$TODO_DIR" "$ICEBOX_DIR"; do
+    [ -d "$dir" ] && SEARCH_DIRS="$SEARCH_DIRS $dir"
+done
 
 # Build grep pattern: keyword1|keyword2|keyword3
 PATTERN=$(echo "$@" | tr ' ' '|')
 
 # Search and count matches per file, sort by count descending
-grep -rilE -m 10 "$PATTERN" "$ARCHIVE_DIR" 2>/dev/null | while read -r file; do
+grep -rilE -m 10 "$PATTERN" $SEARCH_DIRS 2>/dev/null | while read -r file; do
     count=$(grep -ciE -m 10 "$PATTERN" "$file" 2>/dev/null || echo 0)
     echo "$count $file"
 done | sort -rn | head -10
```

> **Note**: This patch is speculative - verify the exact line numbers and whitespace before applying. The `$SEARCH_DIRS` is intentionally unquoted to allow word splitting across multiple directories.

### `plugins/work/agents/discoverer.md`

```diff
--- a/plugins/work/agents/discoverer.md
+++ b/plugins/work/agents/discoverer.md
@@ -1,7 +1,7 @@
 ---
 name: discoverer
-description: Context discovery agent supporting history, source, and ticket analysis modes.
+description: Context discovery agent supporting history, source, and policy analysis modes.
 tools: Bash, Read, Glob, Grep
 model: opus
 skills:
@@ -10,7 +10,7 @@
 
 # Discoverer
 
-Multipurpose context discovery agent. Follow the preloaded **discover** skill, using the section that matches the requested mode.
+Multipurpose context discovery agent. Follow the preloaded **discover** skill, using the section that matches the requested mode.
 
 ## Input
 
@@ -18,14 +18,14 @@
 You will receive:
-- Mode: `history`, `source`, or `ticket`
+- Mode: `history`, `source`, or `policy`
 - Description of the feature/change being planned
 
 ## Mode Routing
 
 | Mode | Skill Section | Purpose |
 | ---- | ------------- | ------- |
-| `history` | Discover History | Search archived tickets for related past work |
+| `history` | Discover History | Search all tickets for related work and check for duplicates |
 | `source` | Discover Source | Explore codebase for relevant files and code flow |
-| `ticket` | Discover Ticket | Analyze existing tickets for duplicates/merge/split |
+| `policy` | Discover Policy | Identify repository standards, conventions, and architecture |
 
 ## Output
```

### `plugins/work/README.md`

```diff
--- a/plugins/work/README.md
+++ b/plugins/work/README.md
@@ -31,7 +31,7 @@
 | Agent                 | Description                                             |
 | --------------------- | ------------------------------------------------------- |
 | `drive-navigator`     | Route and prioritize tickets for /drive                 |
-| `discoverer`          | Context discovery (history, source, ticket modes)       |
+| `discoverer`          | Context discovery (history, source, policy modes)       |
 | `ticket-organizer`    | Discover context, check duplicates, and write tickets   |
```

## Considerations

- The merged History mode output schema becomes more complex, combining the historical context fields with the ticket moderation fields. The ticket-organizer must parse both aspects from a single JSON response. A clear schema definition in the skill will be essential to avoid confusion. (`plugins/work/skills/discover/SKILL.md`)
- The `search.sh` script change to search todo/icebox is a shell modification that should be kept simple per the shell script principle. The patch above avoids complex conditionals by using a simple loop and directory existence check. (`plugins/work/skills/discover/scripts/search.sh`)
- The Discover Policy mode needs to work across plugin boundaries (reading `CLAUDE.md`, `.claude/rules/`, `plugins/standards/` content). Since the discoverer already has Glob, Grep, and Read tools, this is feasible, but the skill instructions must provide clear search location guidance to avoid excessive exploration. (`plugins/work/skills/discover/SKILL.md`)
- The ticket-organizer currently expects the ticket moderation result from a separate discoverer (ticket) call. After the merge, section 3 (Handle Moderation Result) must read moderation status from the history discoverer's output. This is a subtle but critical routing change. (`plugins/work/agents/ticket-organizer.md` lines 39-44)
- Policy discovery results should inform ticket creation but the create-ticket skill does not currently have a section for policy/standards context. Consider whether to add a "Standards Context" section to tickets or fold policy findings into the existing "Considerations" section. (`plugins/work/skills/create-ticket/SKILL.md`)
- The standards plugin itself (`plugins/standards/`) contains policy definitions (lead skills, analysis skills) that the Policy Discoverer would examine. This creates a useful feedback loop where ticket creation is informed by the repository's own quality standards. (`plugins/standards/skills/lead-*/SKILL.md`)

## Final Report

### Changes Made

1. **`plugins/work/skills/discover/scripts/search.sh`** - Expanded search scope from archive-only to archive + todo + icebox directories using a simple loop to collect existing directories
2. **`plugins/work/skills/discover/SKILL.md`** - Merged Discover Ticket section into Discover History (added overlap analysis criteria and combined output schema with `moderation` field); removed Discover Ticket section entirely; added new Discover Policy section with search locations, discovery categories, evaluation process, and output schema
3. **`plugins/work/agents/discoverer.md`** - Updated description, mode list, and routing table from history/source/ticket to history/source/policy
4. **`plugins/work/agents/ticket-organizer.md`** - Changed parallel discovery from ticket mode to policy mode; updated moderation result handling to read from history discoverer's `moderation` field; added policy discovery usage for informing Considerations section
5. **`plugins/work/README.md`** - Updated discoverer and discover skill descriptions to reflect new modes

### Test Plan

- [ ] Run `search.sh` with keywords and verify results include todo/icebox tickets alongside archive
- [ ] Invoke discoverer in history mode and verify combined output with `moderation` field
- [ ] Invoke discoverer in policy mode and verify standards/conventions JSON output
- [ ] Run `/ticket` end-to-end and verify three parallel discoverers (history, source, policy) complete successfully
- [ ] Verify duplicate detection still works via history mode's moderation result

### Release Prep

- No version bump needed (internal plugin refactoring)
- No new dependencies introduced
- No breaking changes to external interfaces
