---
created_at: 2026-01-26T20:28:28+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Rename /sync-work to /sync-workaholic

## Overview

Rename the `/sync-work` command to `/sync-workaholic` to align with the directory rename from `.work/` to `.workaholic/`. The command name should match the directory it operates on.

## Key Files

- `plugins/core/commands/sync-work.md` - Rename to `sync-workaholic.md` and update `name` field
- `plugins/core/README.md` - Update command reference from `/sync-work` to `/sync-workaholic`

## Implementation Steps

1. Rename the command file:
   ```bash
   git mv plugins/core/commands/sync-work.md plugins/core/commands/sync-workaholic.md
   ```

2. Update the frontmatter in the renamed file:
   ```yaml
   ---
   name: sync-workaholic
   description: Sync source code changes to .workaholic/ directory (specs and terminology)
   ---
   ```

3. Update the H1 title from "# Sync Work" to "# Sync Workaholic"

4. Update `plugins/core/README.md` command table:
   - Change `/sync-work` to `/sync-workaholic`

## Considerations

- Using `git mv` preserves history
- The internal content of the file already references `.workaholic/` so no other changes needed
- Users accustomed to `/sync-work` will need to use the new command name
