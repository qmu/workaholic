---
created_at: 2026-04-10T00:21:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 0.25h
commit_hash: c8d5ad6
category: Added
---

# Add dependency tracking to split tickets via YAML frontmatter

## Overview

When the ticket-organizer splits a request into multiple tickets, the resulting tickets lack dependency information. The drive-navigator cannot determine execution order -- it does not know that Ticket B requires Ticket A to be completed first. Add a `depends_on` frontmatter field (list of ticket filenames) so that split tickets carry explicit ordering constraints, and update the drive-navigator to perform topological sorting based on these dependencies.

## Key Files

- `plugins/work/skills/create-ticket/SKILL.md` - Ticket format and frontmatter schema; add `depends_on` field definition
- `plugins/work/agents/ticket-organizer.md` - Splitting logic in step 5; must populate `depends_on` in dependent tickets
- `plugins/work/agents/drive-navigator.md` - Priority/ordering logic; must read `depends_on` and build execution order
- `plugins/work/hooks/validate-ticket.sh` - Frontmatter validation; add optional `depends_on` validation
- `plugins/work/skills/drive/scripts/update.sh` - Frontmatter update script; may need awareness of new field
- `plugins/work/skills/discover/SKILL.md` - Discovery skill; `depends_on` is not relevant here but good to be aware of schema changes

## Related History

The ticket frontmatter schema has been incrementally built through multiple iterations, starting with basic YAML fields and progressing through validation hooks and structured enforcement. The drive-navigator's prioritization logic was introduced to replace simple alphabetical ordering.

Past tickets that touched similar areas:

- [20260124210721-ticket-yaml-frontmatter.md](.workaholic/tickets/archive/feat-20260124-200439/20260124210721-ticket-yaml-frontmatter.md) - Original YAML frontmatter schema (same layer: Config)
- [20260128012837-enforce-ticket-frontmatter.md](.workaholic/tickets/archive/feat-20260128-012023/20260128012837-enforce-ticket-frontmatter.md) - Enforced frontmatter rules and validation (same layer: Config)
- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - Added intelligent ticket prioritization to drive-navigator (same file: drive-navigator.md)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-203938/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Restructured ticket-organizer (same file: ticket-organizer.md)
- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added ticket validation hook (same file: validate-ticket.sh)

## Implementation Steps

1. **Add `depends_on` field to create-ticket skill frontmatter schema** (`plugins/work/skills/create-ticket/SKILL.md`)

   Add `depends_on` as an optional field in the frontmatter template, after `category`. It accepts a YAML list of ticket filenames (just the filename, not the full path). Document that this field is populated by the ticket-organizer when splitting and should not be manually set in most cases.

   Update the Frontmatter Template section:
   ```yaml
   ---
   created_at: $(date -Iseconds)
   author: $(git config user.email)
   type: <enhancement | bugfix | refactoring | housekeeping>
   layer: [<UX | Domain | Infrastructure | DB | Config>]
   effort:
   commit_hash:
   category:
   depends_on:
   ---
   ```

   Add documentation for the field under "Field Requirements":
   - **depends_on**: Optional. List of ticket filenames that must be implemented before this ticket. Populated automatically when the ticket-organizer splits a request. Format: YAML list of filenames (e.g., `[20260410002111-foundation.md]`). Leave empty for standalone tickets.

2. **Update ticket-organizer splitting logic** (`plugins/work/agents/ticket-organizer.md`)

   In step 5 ("Write Ticket(s)"), under the "If splitting" subsection, add instructions to populate `depends_on`:

   - When generating multiple tickets, determine dependency order among them
   - The first ticket (foundation) has no `depends_on` (leave empty)
   - Subsequent tickets that depend on earlier ones list the prerequisite filenames in `depends_on`
   - Only add dependencies where there is a genuine implementation ordering requirement (shared files, API contracts, schema changes needed first)

3. **Update drive-navigator to read `depends_on` and topologically sort** (`plugins/work/agents/drive-navigator.md`)

   In the "Normal Mode" section, step 2 ("Determine Priority Order"), add dependency-aware ordering:

   - After reading YAML frontmatter, also extract `depends_on` field
   - Build a dependency graph from `depends_on` references
   - Perform topological sort: tickets with no dependencies come first, then tickets whose dependencies are satisfied
   - If a cycle is detected (should not happen with well-formed tickets), warn and fall back to type-based priority
   - Within the same dependency tier, fall back to existing type-based priority (bugfix > enhancement > refactoring > housekeeping)
   - In the priority display (step 3), annotate dependent tickets: `3. 20260410-feature-b.md [depends on: 20260410-feature-a.md]`

4. **Add `depends_on` validation to ticket hook** (`plugins/work/hooks/validate-ticket.sh`)

   Add optional validation for the `depends_on` field:

   - If `depends_on` is present and non-empty, parse it as a YAML list
   - Each entry must match the ticket filename pattern (`YYYYMMDDHHmmss-*.md`)
   - Each referenced ticket must exist in `todo/` or `icebox/` (warn but do not block if not found, since the referenced ticket may not yet be written when validating during a split operation)
   - If `depends_on` is empty or absent, pass validation (the field is optional)

5. **Update the frontmatter update script** (`plugins/work/skills/drive/scripts/update.sh`)

   Add `depends_on` to the field insertion order if needed. Since `depends_on` goes after `category`, add a case for it:
   - After `category:` -> `depends_on:`

   This ensures the update script can handle the new field if it ever needs to be programmatically set.

## Patches

### `plugins/work/skills/create-ticket/SKILL.md`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/skills/create-ticket/SKILL.md
+++ b/plugins/work/skills/create-ticket/SKILL.md
@@ -37,6 +37,7 @@
 layer: [<UX | Domain | Infrastructure | DB | Config>]
 effort:
 commit_hash:
 category:
+depends_on:
 ---
 ```
```

### `plugins/work/skills/create-ticket/SKILL.md` (Concrete Example)

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/skills/create-ticket/SKILL.md
+++ b/plugins/work/skills/create-ticket/SKILL.md
@@ -56,6 +56,7 @@
 layer: [UX, Domain]
 effort:
 commit_hash:
 category:
+depends_on:
 ---
 ```
```

### `plugins/work/hooks/validate-ticket.sh`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/hooks/validate-ticket.sh
+++ b/plugins/work/hooks/validate-ticket.sh
@@ -185,5 +185,27 @@
   fi
 fi
 
+# depends_on: optional, YAML list of ticket filenames
+depends_on_line=$(echo "$frontmatter" | grep "^depends_on:")
+if [[ -n "$depends_on_line" ]]; then
+  depends_on_values=$(echo "$depends_on_line" | sed 's/^depends_on:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
+  while IFS= read -r dep; do
+    if [[ -n "$dep" ]]; then
+      # Each entry must match ticket filename pattern
+      if [[ ! "$dep" =~ ^[0-9]{14}-.*\.md$ ]]; then
+        echo "Error: depends_on entries must match YYYYMMDDHHmmss-*.md pattern" >&2
+        echo "Got: $dep" >&2
+        print_skill_reference
+        exit 2
+      fi
+    fi
+  done <<< "$depends_on_values"
+fi
+
 # All validations passed
 exit 0
```

### `plugins/work/skills/drive/scripts/update.sh`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/work/skills/drive/scripts/update.sh
+++ b/plugins/work/skills/drive/scripts/update.sh
@@ -43,6 +43,9 @@
         category)
             sed -i.bak "/^commit_hash:/a\\
 ${FIELD}: ${VALUE}" "$TICKET" ;;
+        depends_on)
+            sed -i.bak "/^category:/a\\
+${FIELD}: ${VALUE}" "$TICKET" ;;
         *)
             echo "Error: Unknown field: $FIELD"
             exit 1 ;;
```

## Considerations

- The `depends_on` field uses filenames only (not full paths) because all tickets in a split batch land in the same directory (`todo/`), making paths redundant (`plugins/work/skills/create-ticket/SKILL.md`)
- The validation hook should warn but not block on missing referenced tickets, since during a split operation the dependent ticket may be validated before the prerequisite ticket file is fully written (`plugins/work/hooks/validate-ticket.sh` lines 56-59)
- Topological sort in the drive-navigator is described in prose rather than a shell script because the navigator is a subagent with access to Read/Bash tools and can implement the sort inline; however, if complexity grows, extracting to a script would follow the shell script principle (`plugins/work/agents/drive-navigator.md`)
- The `depends_on` field should be ignored when a ticket is used standalone (not part of a split) -- the empty value is the default and signals no dependencies (`plugins/work/skills/create-ticket/SKILL.md`)
- Circular dependency detection should produce a clear warning rather than silently breaking the drive loop (`plugins/work/agents/drive-navigator.md` lines 56-68)
- The File Structure template in create-ticket SKILL.md also needs updating to include `depends_on` in the full example (`plugins/work/skills/create-ticket/SKILL.md` lines 89-98)

## Final Report

### Changes Made

- **plugins/work/skills/create-ticket/SKILL.md**: Added `depends_on:` to frontmatter template, concrete example, file structure template; added field documentation under new "Optional" subsection; updated field count from 7 to 8 in common mistakes table
- **plugins/work/agents/ticket-organizer.md**: Added `depends_on` population instructions in the "If splitting" subsection of step 5
- **plugins/work/agents/drive-navigator.md**: Added `depends_on` extraction in step 1; rewrote step 2 to prioritize dependency ordering (topological sort) before type-based severity; updated example output to show dependency annotation
- **plugins/work/hooks/validate-ticket.sh**: Added optional `depends_on` validation — parses YAML list entries and validates each matches `YYYYMMDDHHmmss-*.md` pattern; uses `|| true` to handle absent field gracefully under `set -e`
- **plugins/work/skills/drive/scripts/update.sh**: Added `depends_on` case to field insertion order (inserted after `category:`)

### Test Plan

- Validated existing ticket (no `depends_on`) passes hook: exit 0
- Validated ticket with valid `depends_on: [20260410002111-foundation.md]` passes hook: exit 0
- Validated ticket with invalid `depends_on: [bad-filename.md]` fails hook: exit 2 with pattern error
- Verified `update.sh` correctly inserts `depends_on` field after `category` in frontmatter
