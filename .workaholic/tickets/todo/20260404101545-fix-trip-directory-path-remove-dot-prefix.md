---
created_at: 2026-04-04T10:15:45+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
---

# Fix trip directory path: rename `.trips` to `trips`

## Overview

The trip command and related skills store trip artifacts under `.workaholic/.trips/` (with a leading dot on `trips`). The directory should be `.workaholic/trips/` (without the leading dot) to be consistent with other `.workaholic/` subdirectories like `stories/`, `specs/`, `policies/`, `tickets/`, etc. The leading dot makes the directory hidden and implies it is transient, but trip artifacts are committed to git and are persistent project data.

## Key Files

- `plugins/work/skills/trip-protocol/scripts/init-trip.sh` - Hardcodes `.workaholic/.trips/` as the trip artifact root (line 24)
- `plugins/work/skills/trip-protocol/SKILL.md` - Documents `.workaholic/.trips/<trip-name>/` as the artifact storage path (line 51)
- `plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh` - Hardcodes `.workaholic/.trips/` when locating trip artifacts (line 19)
- `plugins/work/skills/trip-protocol/scripts/trip-commit.sh` - Uses `find` pattern `*/.trips/*/event-log.md` to locate event log (line 24)
- `plugins/core/skills/branching/scripts/detect-context.sh` - Hardcodes `.workaholic/.trips` when detecting trip mode (line 18)
- `plugins/core/commands/report.md` - References `.workaholic/.trips/` in trip mode instructions (line 55)

## Related History

The `.trips` path was established when the trip command was first implemented and has been carried through subsequent refactors. Multiple past tickets have referenced this path without changing it.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Original trip command implementation that established the `.trips` path convention
- [20260319163917-fix-workaholic-path-resolution-in-worktrees.md](.workaholic/tickets/archive/trip/trip-20260319-040153/20260319163917-fix-workaholic-path-resolution-in-worktrees.md) - Fixed path resolution for `.workaholic/.trips/` in worktrees (same path)
- [20260404014401-unify-branch-naming-work-timestamp-feature.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014401-unify-branch-naming-work-timestamp-feature.md) - Unified branch naming, referenced `.trips/` for mode detection

## Implementation Steps

1. Update `plugins/work/skills/trip-protocol/scripts/init-trip.sh`: Change `.workaholic/.trips/` to `.workaholic/trips/` on line 24 and update the comment on line 2
2. Update `plugins/work/skills/trip-protocol/SKILL.md`: Change `.workaholic/.trips/` to `.workaholic/trips/` in the Artifact Storage section (line 51)
3. Update `plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh`: Change `.workaholic/.trips/` to `.workaholic/trips/` on line 19
4. Update `plugins/work/skills/trip-protocol/scripts/trip-commit.sh`: Change the find pattern from `*/.trips/*/event-log.md` to `*/trips/*/event-log.md` on line 24
5. Update `plugins/core/skills/branching/scripts/detect-context.sh`: Change `.workaholic/.trips` to `.workaholic/trips` on line 18
6. Update `plugins/core/commands/report.md`: Change `.workaholic/.trips/` to `.workaholic/trips/` on line 55
7. Rename the existing directory on disk: `git mv .workaholic/.trips .workaholic/trips`

## Patches

### `plugins/work/skills/trip-protocol/scripts/init-trip.sh`

```diff
--- a/plugins/work/skills/trip-protocol/scripts/init-trip.sh
+++ b/plugins/work/skills/trip-protocol/scripts/init-trip.sh
@@ -1,5 +1,5 @@
 #!/bin/bash
-# Initialize a trip directory structure under .workaholic/.trips/
+# Initialize a trip directory structure under .workaholic/trips/
 # Usage: bash init-trip.sh <trip-name> [instruction]
 # The optional instruction argument is the user's original trip description.
 # Output: JSON with trip_path and plan_path
@@ -21,7 +21,7 @@
 
 root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
 
-trip_path="${root}/.workaholic/.trips/${trip_name}"
+trip_path="${root}/.workaholic/trips/${trip_name}"
 
 if [ -d "$trip_path" ]; then
```

### `plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh`

```diff
--- a/plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh
+++ b/plugins/work/skills/write-trip-report/scripts/gather-artifacts.sh
@@ -16,7 +16,7 @@
 
 root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
 
-trip_path="${root}/.workaholic/.trips/${trip_name}"
+trip_path="${root}/.workaholic/trips/${trip_name}"
 
 if [ ! -d "$trip_path" ]; then
```

### `plugins/work/skills/trip-protocol/scripts/trip-commit.sh`

```diff
--- a/plugins/work/skills/trip-protocol/scripts/trip-commit.sh
+++ b/plugins/work/skills/trip-protocol/scripts/trip-commit.sh
@@ -21,7 +21,7 @@
   git add -A
 
   # Soft guardrail: warn if event-log.md exists but was not modified in this commit
-  event_log=$(find . -path '*/.trips/*/event-log.md' -print -quit 2>/dev/null || true)
+  event_log=$(find . -path '*/trips/*/event-log.md' -print -quit 2>/dev/null || true)
   if [ -n "$event_log" ] && [ -f "$event_log" ]; then
     if ! git diff --cached --name-only | grep -q 'event-log.md'; then
```

### `plugins/core/skills/branching/scripts/detect-context.sh`

```diff
--- a/plugins/core/skills/branching/scripts/detect-context.sh
+++ b/plugins/core/skills/branching/scripts/detect-context.sh
@@ -15,7 +15,7 @@
 
 # Detect mode from workspace artifacts
 detect_mode() {
-  local trips_dir="${root}/.workaholic/.trips"
+  local trips_dir="${root}/.workaholic/trips"
   local todo_dir="${root}/.workaholic/tickets/todo"
   local has_trips=false
   local has_tickets=false
```

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -52,7 +52,7 @@
 
 ##### Trip Mode (`mode: "trip"`)
 
-1. Locate the trip directory at `.workaholic/.trips/`. Find the most recent trip directory. If none exists, inform the user and stop.
+1. Locate the trip directory at `.workaholic/trips/`. Find the most recent trip directory. If none exists, inform the user and stop.
 2. **Gather artifacts**: `bash ${CLAUDE_PLUGIN_ROOT}/../work/skills/write-trip-report/scripts/gather-artifacts.sh "<trip-name>"`
 3. **Generate report**: Follow the preloaded **write-trip-report** skill. Write to `.workaholic/stories/<branch-name>.md`.
```

### `plugins/work/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/work/skills/trip-protocol/SKILL.md
+++ b/plugins/work/skills/trip-protocol/SKILL.md
@@ -48,7 +48,7 @@
 ## Artifact Storage
 
 ```
-.workaholic/.trips/<trip-name>/
+.workaholic/trips/<trip-name>/
   directions/           # Planner: direction-v1.md, direction-v2.md, ...
   models/               # Architect: model-v1.md, model-v2.md, ...
   designs/              # Constructor: design-v1.md, design-v2.md, ...
```

## Considerations

- The existing `.workaholic/.trips/trip-20260319-040153/` directory on disk needs to be renamed via `git mv` as part of implementation. This directory contains committed trip artifacts. (`plugins/work/skills/trip-protocol/scripts/init-trip.sh`)
- Numerous documentation files under `.workaholic/specs/`, `.workaholic/terms/`, `.workaholic/guides/`, and `.workaholic/policies/` reference `.workaholic/.trips/`. These are descriptive documentation rather than executable code, so they will not cause runtime failures, but they should ideally be updated for consistency. The scope of documentation updates is large (30+ files) and could be handled as a separate housekeeping ticket. (`.workaholic/specs/`, `.workaholic/terms/`, `.workaholic/guides/`, `.workaholic/policies/`)
- Archived ticket files also reference `.workaholic/.trips/` but archived tickets are historical records and should not be modified. (`.workaholic/tickets/archive/`)
- The `trip-commit.sh` find pattern `*/trips/*/event-log.md` (after fix) is slightly broader than the original `*/.trips/*/event-log.md` since `trips` without a dot is a more common directory name. In practice this is not a concern because the find is scoped to the git working directory. (`plugins/work/skills/trip-protocol/scripts/trip-commit.sh` line 24)
