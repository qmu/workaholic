---
created_at: 2026-01-29T09:46:18+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Fix create-branch Script Path Reference

## Overview

The `/ticket` command and `create-branch` skill reference a non-existent path `.claude/skills/create-branch/sh/create.sh`. The actual path is `plugins/core/skills/create-branch/sh/create.sh`. Instead of hardcoding paths, use `@` import syntax to embed the script content inline, making it work regardless of installation location.

## Key Files

- `plugins/core/commands/ticket.md` - Line 21 references broken path
- `plugins/core/skills/create-branch/SKILL.md` - Line 17 references broken path
- `plugins/core/skills/create-branch/sh/create.sh` - The actual script to inline

## Related History

This path mismatch occurred as the plugin structure evolved. The `@` import syntax provides a robust solution by embedding content rather than referencing external files.

## Implementation Steps

1. Update `plugins/core/skills/create-branch/SKILL.md` to embed script via `@` import:

   Replace the code block with inline script reference:
   ```markdown
   Run this script with a branch prefix:

   @sh/create.sh
   ```

   Or embed the script directly (it's only 10 lines):
   ```bash
   PREFIX="$1"
   if [ -z "$PREFIX" ]; then
       echo "Usage: <prefix> (feat, fix, refact)"
       exit 1
   fi
   TIMESTAMP=$(date +%Y%m%d-%H%M%S)
   BRANCH="${PREFIX}-${TIMESTAMP}"
   git checkout -b "$BRANCH"
   echo "$BRANCH"
   ```

2. Update `plugins/core/commands/ticket.md` line 21:

   Replace:
   ```
   2. Run: `bash .claude/skills/create-branch/sh/create.sh <prefix>`
   ```

   With inline commands (script is simple enough):
   ```
   2. Create branch: `git checkout -b "<prefix>-$(date +%Y%m%d-%H%M%S)"`
   ```

3. Remove `plugins/core/skills/create-branch/sh/create.sh` if no longer needed (script logic is now inline).

## Considerations

- The `@` import syntax works for CLAUDE.md files and may work for skills (test this)
- Inlining the script is simpler since it's only 2 meaningful commands
- Alternative: use `${CLAUDE_PLUGIN_ROOT}` environment variable for hooks, but this doesn't apply to skills/commands
- The ticket command preloads `create-branch` skill, so the skill content is available during execution
