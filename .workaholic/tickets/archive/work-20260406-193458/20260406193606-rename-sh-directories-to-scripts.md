---
created_at: 2026-04-06T19:36:06+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.1h
commit_hash: 5af795a
category: Changed
---

# Rename sh/ directories to scripts/ across the repository

## Overview

Rename the root-level `sh/` directory to `scripts/` and fix two legacy `sh/` path references in standards plugin gather scripts. All plugin skill directories already use `scripts/` -- this ticket addresses the remaining inconsistencies to achieve uniform naming.

## Key Files

- `sh/claude.sh` - Root launcher script; directory rename to `scripts/claude.sh`, update internal usage comment
- `plugins/standards/skills/write-spec/scripts/gather.sh` - Contains stale `${skill_dir}sh/` references that should be `${skill_dir}scripts/`
- `plugins/standards/skills/analyze-viewpoint/scripts/gather.sh` - Contains stale `${skill_dir}sh/` references in the component viewpoint case

## Related History

An earlier ticket renamed `scripts/` to `sh/` for brevity, but a subsequent large-scale refactoring reverted most directories back to `scripts/`. These three locations are the remaining stragglers.

Past tickets that touched similar areas:

- [20260127102007-rename-scripts-to-sh.md](.workaholic/tickets/archive/feat-20260126-214833/20260127102007-rename-scripts-to-sh.md) - Original rename from scripts/ to sh/ (now being reversed)

## Implementation Steps

1. Rename the root `sh/` directory to `scripts/`:
   ```
   git mv sh scripts
   ```

2. Update the usage comment in `scripts/claude.sh` (line 3) from `bash sh/claude.sh` to `bash scripts/claude.sh`

3. Fix stale `sh/` references in `plugins/standards/skills/write-spec/scripts/gather.sh`:
   - Line 56: `"${skill_dir}sh"` to `"${skill_dir}scripts"`
   - Line 57: `"${skill_dir}sh/"*.sh` to `"${skill_dir}scripts/"*.sh`

4. Fix stale `sh/` references in `plugins/standards/skills/analyze-viewpoint/scripts/gather.sh`:
   - Line 113: `"${skill_dir}sh"` to `"${skill_dir}scripts"`
   - Line 114: `"${skill_dir}sh/"*.sh` to `"${skill_dir}scripts/"*.sh`

## Patches

### `sh/claude.sh`

```diff
--- a/sh/claude.sh
+++ b/scripts/claude.sh
@@ -1,5 +1,5 @@
 #!/usr/bin/env bash
 # Launch Claude Code with local workaholic plugins for self-development.
-# Usage: bash sh/claude.sh [additional claude args...]
+# Usage: bash scripts/claude.sh [additional claude args...]
 
 set -euo pipefail
```

### `plugins/standards/skills/write-spec/scripts/gather.sh`

```diff
--- a/plugins/standards/skills/write-spec/scripts/gather.sh
+++ b/plugins/standards/skills/write-spec/scripts/gather.sh
@@ -53,8 +53,8 @@
 for skill_dir in plugins/work/skills/*/; do
   skill_name=$(basename "$skill_dir")
   echo "  ${skill_name}/"
-  if [ -d "${skill_dir}sh" ]; then
-    ls -1 "${skill_dir}sh/"*.sh 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || true
+  if [ -d "${skill_dir}scripts" ]; then
+    ls -1 "${skill_dir}scripts/"*.sh 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || true
   fi
 done
```

### `plugins/standards/skills/analyze-viewpoint/scripts/gather.sh`

```diff
--- a/plugins/standards/skills/analyze-viewpoint/scripts/gather.sh
+++ b/plugins/standards/skills/analyze-viewpoint/scripts/gather.sh
@@ -110,8 +110,8 @@
         for skill_dir in plugins/work/skills/*/; do
             skill_name=$(basename "$skill_dir")
             echo "  ${skill_name}/"
-            if [ -d "${skill_dir}sh" ]; then
-                ls -1 "${skill_dir}sh/"*.sh 2>/dev/null | while read -r f; do
+            if [ -d "${skill_dir}scripts" ]; then
+                ls -1 "${skill_dir}scripts/"*.sh 2>/dev/null | while read -r f; do
                     echo "    $(basename "$f")"
                 done
             fi
```

## Considerations

- The root `sh/` directory contains only `claude.sh` -- a self-development launcher that references stale plugin paths (`drivin`, `trippin`) which no longer exist; those are out of scope for this ticket but worth noting (`scripts/claude.sh` lines 10-12)
- No `sh/` directories exist under `plugins/` -- all 21 skill script directories already use `scripts/`, so the plugin directory renames are not needed
- Historical trip artifacts in `.workaholic/trips/` contain many `sh/` path references in their documentation, but those are archival records and should not be modified

## Final Report

### Changes

- Renamed root `sh/` directory to `scripts/` via `git mv`
- Updated usage comment in `scripts/claude.sh` from `bash sh/claude.sh` to `bash scripts/claude.sh`
- Fixed stale `${skill_dir}sh` references in `plugins/standards/skills/write-spec/scripts/gather.sh`
- Fixed stale `${skill_dir}sh` references in `plugins/standards/skills/analyze-viewpoint/scripts/gather.sh`

### Test Plan

- Verified no remaining `"sh/"` path references in plugin or scripts files via grep
- All changes match the patches specified in the ticket
