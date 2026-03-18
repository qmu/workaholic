---
created_at: 2026-03-18T23:48:16+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 0.25h
commit_hash: 024ca92
category: Added
---

# Add reusable strip-frontmatter shell script

## Overview

Create a dedicated, deterministic shell script that strips YAML frontmatter from a markdown file and outputs clean markdown. The `create-or-update.sh` script currently has an inline awk snippet for frontmatter stripping (lines 24-30), but this approach has two problems: (1) the logic is embedded inline violating the Shell Script Principle, and (2) it is not reusable by other components such as the trip report PR creation path. Extracting this into a standalone skill script ensures every PR description path produces clean markdown with zero frontmatter contamination.

## Key Files

- `plugins/drivin/skills/create-pr/sh/create-or-update.sh` - Current inline awk frontmatter stripping (lines 24-30), replace with call to new script
- `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh` - New standalone script to create
- `plugins/drivin/skills/create-pr/SKILL.md` - Update documentation to mention the strip-frontmatter script

## Related History

The PR creation pipeline was extracted into a dedicated skill with bundled script, and story files were designated as the single source of truth for PR descriptions. Frontmatter stripping was added inline at that time but never extracted as a reusable component.

Past tickets that touched similar areas:

- [20260127021024-extract-pr-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021024-extract-pr-skill.md) - Extracted PR operations into dedicated skill with bash script (same layer: Infrastructure)
- [20260124005056-story-as-pr-description.md](.workaholic/tickets/archive/feat-20260123-191707/20260124005056-story-as-pr-description.md) - Made story file the PR description source of truth (same pipeline)
- [20260131192725-improve-create-ticket-frontmatter-clarity.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192725-improve-create-ticket-frontmatter-clarity.md) - Improved frontmatter conventions (same domain: frontmatter handling)

## Implementation Steps

1. Create `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh` — a shell script that reads a markdown file path as argument, strips YAML frontmatter (everything between the opening `---` and closing `---` inclusive), and writes the clean body to stdout. The script must handle: files with frontmatter, files without frontmatter (pass through unchanged), and empty files. Use `sed` with a simple range deletion pattern (`1{/^---$/,/^---$/d}`) for deterministic behavior.
2. Update `plugins/drivin/skills/create-pr/sh/create-or-update.sh` to replace the inline awk snippet (lines 24-30) with a call to `strip-frontmatter.sh` in the same directory, piping output to `/tmp/pr-body.md`.
3. Update `plugins/drivin/skills/create-pr/SKILL.md` to document the strip-frontmatter script as a reusable component available for any markdown-to-PR-body conversion.

## Patches

### `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh`

```diff
--- /dev/null
+++ b/plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh
@@ -0,0 +1,20 @@
+#!/bin/sh -eu
+# Strip YAML frontmatter from a markdown file
+# Usage: strip-frontmatter.sh <file>
+# Outputs clean markdown body to stdout
+
+set -eu
+
+FILE="${1:-}"
+
+if [ -z "$FILE" ]; then
+    echo "Usage: strip-frontmatter.sh <file>" >&2
+    exit 1
+fi
+
+if [ ! -f "$FILE" ]; then
+    echo "Error: File not found: $FILE" >&2
+    exit 1
+fi
+
+# Remove frontmatter: delete from first --- to next ---
+sed '1{/^---$/,/^---$/d}' "$FILE"
```

### `plugins/drivin/skills/create-pr/sh/create-or-update.sh`

```diff
--- a/plugins/drivin/skills/create-pr/sh/create-or-update.sh
+++ b/plugins/drivin/skills/create-pr/sh/create-or-update.sh
@@ -21,13 +21,8 @@
     exit 1
 fi

-# Strip YAML frontmatter, write to temp file
-awk '
-  BEGIN { fm=0; fc=0 }
-  /^---$/ { fc++; if (fc <= 2) { fm=1; next } }
-  fc == 2 && fm { fm=0; next }
-  fm { next }
-  { print }
-' "$STORY_FILE" >| /tmp/pr-body.md
+# Strip YAML frontmatter using bundled script, write to temp file
+SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
+"${SCRIPT_DIR}/strip-frontmatter.sh" "$STORY_FILE" >| /tmp/pr-body.md

 # Check if PR exists
```

## Considerations

- The `sed '1{/^---$/,/^---$/d}'` pattern only matches frontmatter starting on line 1, which is the correct YAML frontmatter convention — content `---` separators elsewhere in the document are preserved (`plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh`)
- The trip report path in `plugins/core/commands/report.md` (Trip Context step 5) creates PRs directly via `gh pr create` without using `create-or-update.sh` — if trip reports ever gain frontmatter, that path should also call `strip-frontmatter.sh` (`plugins/core/commands/report.md` lines 41-48)
- The script uses `SCRIPT_DIR` relative resolution so it works regardless of the caller's working directory (`plugins/drivin/skills/create-pr/sh/create-or-update.sh`)

## Final Report

### Changes Made

- Created `plugins/drivin/skills/create-pr/sh/strip-frontmatter.sh` — standalone reusable script for stripping YAML frontmatter from markdown files
- Updated `plugins/drivin/skills/create-pr/sh/create-or-update.sh` — replaced 7-line inline awk snippet with call to `strip-frontmatter.sh` via `SCRIPT_DIR` resolution
- Updated `plugins/drivin/skills/create-pr/SKILL.md` — documented the strip-frontmatter script as a reusable component

### Discovered

- The ticket's suggested `sed '1{/^---$/,/^---$/d}'` pattern does not work: `1{...}` restricts execution to line 1 only, so the range never spans to the closing `---`. Replaced with a correct `awk` one-liner that handles all three cases (with frontmatter, without frontmatter, empty files) and preserves `---` separators elsewhere in the document.
