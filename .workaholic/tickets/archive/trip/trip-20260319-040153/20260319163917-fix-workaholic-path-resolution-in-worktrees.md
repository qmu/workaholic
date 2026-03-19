---
created_at: 2026-03-19T16:39:17+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure, Config]
effort: 0.5h
commit_hash: 571f954
category: Changed
---

# Fix .workaholic Path Resolution for Worktree Compatibility

## Overview

When `/drive` runs inside a trip worktree (`.worktrees/trip-xxx/`), drivin shell scripts that reference `.workaholic` use relative paths from the current working directory. While `git rev-parse --show-toplevel` correctly returns the worktree root (not the main repo root) inside worktrees, the real issue is that several scripts are invoked from contexts where the working directory may not be the worktree root. Additionally, `system-safety/detect.sh` uses `git rev-parse --show-toplevel` to resolve the repo root and then constructs absolute paths from it, which works correctly in worktrees but may fail if the script is called from a subdirectory. All scripts using relative `.workaholic/` paths depend on being executed from the repository or worktree root directory. This ticket ensures all drivin shell scripts that access `.workaholic/` explicitly resolve to the correct root directory, making trip+drive fully compatible.

## Key Files

- `plugins/drivin/skills/system-safety/sh/detect.sh` - Uses `git rev-parse --show-toplevel` to set `repo_root`; constructs absolute paths from it for file checks. This is correct for worktrees but should also be the pattern for other scripts.
- `plugins/drivin/skills/discover-history/sh/search.sh` - Uses relative `ARCHIVE_DIR=".workaholic/tickets/archive"`; will fail if invoked from non-root directory
- `plugins/drivin/skills/gather-git-context/sh/gather.sh` - Uses relative `ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"`
- `plugins/drivin/skills/write-terms/sh/gather.sh` - Uses relative `.workaholic/tickets/archive/` and `find .workaholic/terms`
- `plugins/drivin/skills/write-spec/sh/gather.sh` - Uses relative `.workaholic/tickets/archive/` and `find .workaholic/specs`
- `plugins/drivin/skills/write-changelog/sh/generate.sh` - Uses relative `.workaholic/tickets/archive/${BRANCH}`
- `plugins/drivin/skills/analyze-viewpoint/sh/gather.sh` - Uses relative `.workaholic/` paths extensively (tickets, specs, terms)
- `plugins/drivin/skills/analyze-policy/sh/gather.sh` - Uses relative `find .workaholic/policies`
- `plugins/drivin/skills/create-pr/sh/create-or-update.sh` - Uses relative `STORY_FILE=".workaholic/stories/${BRANCH}.md"`
- `plugins/drivin/skills/select-scan-agents/sh/select.sh` - Uses `.workaholic/tickets/*` and `.workaholic/terms/*` in case patterns
- `plugins/core/skills/branching/sh/detect-context.sh` - Uses relative `find .workaholic/tickets/todo`
- `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` - Uses relative `.workaholic/.trips/`
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` - Uses relative `.workaholic/.trips/`

## Related History

The worktree isolation model was established through the trip-protocol skill, and cross-command compatibility between trip and drive was implemented in drive-20260312-102414. The archive script was already fixed to sanitize branch names with slashes. However, no ticket has yet addressed the fundamental issue that drivin shell scripts assume they run from the repository root and use bare relative `.workaholic/` paths.

Past tickets that touched similar areas:

- [20260316143858-trip-drive-cross-command-compatibility.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143858-trip-drive-cross-command-compatibility.md) - Designed the trip+drive hybrid workflow; noted that tickets in worktrees stay within worktree's git history (same concern: worktree path resolution)
- [20260316143754-add-worktree-detection-guard.md](.workaholic/tickets/archive/drive-20260312-102414/20260316143754-add-worktree-detection-guard.md) - Added worktree detection guard to /drive and /ticket commands (same layer: Infrastructure)
- [20260129101447-fix-archive-script-path-reference.md](.workaholic/tickets/archive/main/20260129101447-fix-archive-script-path-reference.md) - Fixed path reference in archive script; noted `${CLAUDE_PLUGIN_ROOT}` as future consideration (same concern: path portability)
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Established dev environment validation for trip worktrees (same layer: Infrastructure)

## Implementation Steps

1. **Create a shared `resolve-workaholic-root.sh` utility script** in `plugins/drivin/skills/` (or a new shared location):
   - Use `git rev-parse --show-toplevel` to find the worktree/repo root
   - Output the absolute path to the `.workaholic` directory
   - This becomes the canonical way all scripts locate `.workaholic`
   - Example: `WORKAHOLIC_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.workaholic"`

2. **Update `plugins/drivin/skills/discover-history/sh/search.sh`**:
   - Replace `ARCHIVE_DIR=".workaholic/tickets/archive"` with root-resolved absolute path
   - Resolve root at script start: `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`
   - Use `ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive"`

3. **Update `plugins/drivin/skills/gather-git-context/sh/gather.sh`**:
   - Replace relative `ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"` with root-resolved path

4. **Update `plugins/drivin/skills/write-terms/sh/gather.sh`**:
   - Replace relative `.workaholic/tickets/archive/` and `find .workaholic/terms` with root-resolved paths

5. **Update `plugins/drivin/skills/write-spec/sh/gather.sh`**:
   - Replace relative `.workaholic/` references with root-resolved paths

6. **Update `plugins/drivin/skills/write-changelog/sh/generate.sh`**:
   - Replace relative `ARCHIVE_DIR` with root-resolved path

7. **Update `plugins/drivin/skills/analyze-viewpoint/sh/gather.sh`**:
   - This script has the most `.workaholic` references (tickets, specs, terms in multiple case branches)
   - Replace all relative `.workaholic/` paths with root-resolved equivalents

8. **Update `plugins/drivin/skills/analyze-policy/sh/gather.sh`**:
   - Replace `find .workaholic/policies` with root-resolved path

9. **Update `plugins/drivin/skills/create-pr/sh/create-or-update.sh`**:
   - Replace `STORY_FILE=".workaholic/stories/${BRANCH}.md"` with root-resolved path

10. **Update `plugins/core/skills/branching/sh/detect-context.sh`**:
    - Replace `find .workaholic/tickets/todo` with root-resolved path

11. **Update `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh`** and `plugins/trippin/skills/trip-protocol/sh/init-trip.sh`**:
    - Replace relative `.workaholic/.trips/` with root-resolved paths

12. **Verify all scripts work from non-root directories** by running each script from a subdirectory within a worktree and confirming they locate `.workaholic/` correctly.

## Patches

### `plugins/drivin/skills/discover-history/sh/search.sh`

```diff
--- a/plugins/drivin/skills/discover-history/sh/search.sh
+++ b/plugins/drivin/skills/discover-history/sh/search.sh
@@ -10,7 +10,9 @@
     exit 1
 fi

-ARCHIVE_DIR=".workaholic/tickets/archive"
+ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
+
+ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive"

 # Build grep pattern: keyword1|keyword2|keyword3
 PATTERN=$(echo "$@" | tr ' ' '|')
```

### `plugins/drivin/skills/gather-git-context/sh/gather.sh`

```diff
--- a/plugins/drivin/skills/gather-git-context/sh/gather.sh
+++ b/plugins/drivin/skills/gather-git-context/sh/gather.sh
@@ -6,6 +6,7 @@
 set -eu

 BRANCH=$(git branch --show-current)
+ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
 BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //')
 REPO_URL_RAW=$(git remote get-url origin)

@@ -16,7 +17,7 @@

 # List archived tickets for the branch (empty array if none)
-ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"
+ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive/${BRANCH}"
 if [ -d "$ARCHIVE_DIR" ]; then
     TICKETS=$(ls -1 "$ARCHIVE_DIR"/*.md 2>/dev/null | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
 else
```

### `plugins/core/skills/branching/sh/detect-context.sh`

```diff
--- a/plugins/core/skills/branching/sh/detect-context.sh
+++ b/plugins/core/skills/branching/sh/detect-context.sh
@@ -5,6 +5,7 @@
 set -euo pipefail

 branch=$(git branch --show-current 2>/dev/null || echo "")
+root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

 if [ -z "$branch" ]; then
   echo '{"context": "unknown", "branch": ""}'
@@ -22,7 +23,7 @@
 if [[ "$branch" == trip/* ]]; then
   trip_name="${branch#trip/}"
   # Check if drive-style tickets exist (trip_drive hybrid)
-  ticket_count=$(find .workaholic/tickets/todo -name '*.md' 2>/dev/null | wc -l)
+  ticket_count=$(find "${root}/.workaholic/tickets/todo" -name '*.md' 2>/dev/null | wc -l)
   if [ "$ticket_count" -gt 0 ]; then
     echo "{\"context\": \"trip_drive\", \"branch\": \"${branch}\", \"trip_name\": \"${trip_name}\"}"
     exit 0
```

> **Note**: The remaining scripts (write-terms, write-spec, write-changelog, analyze-viewpoint, analyze-policy, create-pr, init-trip, gather-artifacts) follow the identical pattern: add `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` at script start and prefix all `.workaholic/` references with `${ROOT}/`. These patches are omitted for brevity as the pattern is mechanical.

## Considerations

- `git rev-parse --show-toplevel` correctly returns the worktree root when run inside a worktree, not the main repository root. This means scripts using this approach will naturally resolve to the worktree's `.workaholic/` directory without special-casing. (`plugins/drivin/skills/system-safety/sh/detect.sh` line 10 already demonstrates this pattern)
- The `select-scan-agents/sh/select.sh` script uses `.workaholic/` in `case` pattern matching against diff output paths, not as filesystem lookups. These patterns match git diff output which always uses repository-relative paths, so they do not need root resolution. (`plugins/drivin/skills/select-scan-agents/sh/select.sh` lines 97-107)
- Adding `ROOT=$(git rev-parse --show-toplevel ...)` to each script introduces a minor performance overhead (one git subprocess per script invocation). An alternative is sourcing a shared utility, but this adds a dependency path that itself needs resolving. The per-script approach is simpler and self-contained. (`plugins/drivin/skills/discover-history/sh/search.sh`)
- Markdown files (SKILL.md, commands, agents) that reference `.workaholic/` in human-readable instructions or documentation do not need path resolution -- they describe paths relative to the repo root, and the LLM agent is expected to resolve them contextually. Only shell scripts that perform filesystem operations need the fix. (`plugins/drivin/commands/drive.md` lines 16, 36, 106, 138)
- The `archive-ticket/sh/archive.sh` already works correctly because it receives the ticket path as an argument and derives the archive directory from it via string manipulation, never using a hardcoded `.workaholic` prefix. (`plugins/drivin/skills/archive-ticket/sh/archive.sh` lines 32-37)
