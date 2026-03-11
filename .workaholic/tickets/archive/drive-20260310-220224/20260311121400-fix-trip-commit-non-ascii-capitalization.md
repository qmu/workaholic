---
created_at: 2026-03-11T12:14:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 0.1h
commit_hash: 1108d20
category: Changed
---

# Fix trip-commit.sh Non-ASCII Agent Name Capitalization

## Overview

The `trip-commit.sh` script capitalizes agent names using `${agent:0:1}` bash substring extraction combined with `tr '[:lower:]' '[:upper:]'`. This works correctly for ASCII agent names (`planner` -> `Planner`) but would produce incorrect output for non-ASCII names because `${agent:0:1}` operates on bytes, not characters, and could extract a partial multibyte sequence.

While current agent names are all ASCII (`planner`, `architect`, `constructor`), this is a latent bug that should be fixed for robustness. Replace the capitalization logic with a single `sed` or `awk` command that correctly handles the full input string.

## Key Files

- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` - Lines 23-24, the capitalization logic

## Related History

- [20260310220756-trip-commit-message-rules.md](.workaholic/tickets/archive/drive-20260310-220224/20260310220756-trip-commit-message-rules.md) - Established the commit message format with `[Agent]` bracket prefix

## Implementation Steps

1. **Replace the capitalization logic** in `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`:
   - Replace lines 23-24:
     ```bash
     # Capitalize agent name for bracket prefix
     agent_cap="$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}"
     ```
   - With a single command that capitalizes the first character safely:
     ```bash
     # Capitalize agent name for bracket prefix
     agent_cap="$(echo "$agent" | sed 's/./\U&/')"
     ```
   - The `sed 's/./\U&/'` approach replaces only the first character (`.` matches one character) with its uppercase equivalent (`\U&`), operating on the string level rather than byte extraction.

## Patches

### `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`

```diff
--- a/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
+++ b/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
@@ -20,8 +20,8 @@
 if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
   git add -A

-  # Capitalize agent name for bracket prefix
-  agent_cap="$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}"
+  # Capitalize first character of agent name for bracket prefix
+  agent_cap="$(echo "$agent" | sed 's/./\U&/')"

   body="Phase: ${phase}
 Step: ${step}"
```

## Considerations

- The `\U` flag in `sed` is a GNU sed extension. This project runs on Linux (Amazon Linux 2023) which uses GNU sed, so this is safe. If macOS compatibility were needed, `awk` would be the alternative: `echo "$agent" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'`. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
- This change is backwards-compatible: for ASCII input, the output is identical. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)

## Final Report

### Changes Made

- Replaced `${agent:0:1}` byte extraction + `tr` with `sed 's/./\U&/'` in `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` (line 24)

### Test Plan

- Verified `sed 's/./\U&/'` produces correct output for all three agent names: planner→Planner, architect→Architect, constructor→Constructor
