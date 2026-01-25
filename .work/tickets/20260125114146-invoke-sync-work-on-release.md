---
date: 2026-01-25
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Invoke /sync-work on Release

## Overview

The `/release` command should invoke `/sync-work` before committing the version bump. This ensures that documentation in `.work/specs/` and `.work/terminology/` is updated to reflect the current codebase state before publishing a new release. Currently, release.md resides in `.claude/commands/` but per project conventions, it should be in `plugins/core/commands/`.

## Key Files

- `.claude/commands/release.md` - Current release command location (to be moved)
- `plugins/core/commands/release.md` - Target location for the command
- `plugins/core/commands/sync-work.md` - Reference for the sync-work command invocation

## Implementation Steps

1. Move `.claude/commands/release.md` to `plugins/core/commands/release.md`
2. Add `sync-work` invocation step before the commit step (between step 8 and 9):
   - Invoke the `/sync-work` command using the Skill tool
   - This will update `.work/specs/` and `.work/terminology/` based on changes
3. Update the commit step to include any documentation changes from sync-work
4. Delete `.claude/commands/release.md` after moving

## Considerations

- The sync-work command may produce no changes if documentation is already up-to-date
- The release commit will now potentially include documentation updates alongside version bumps
- This creates a dependency on the sync-work command being functional
