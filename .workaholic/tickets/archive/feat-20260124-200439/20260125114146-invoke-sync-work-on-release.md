---
date: 2026-01-25
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash: 55dcc77
category: Added
---

# Invoke /sync-work on Release

## Overview

The `/release` command should invoke `/sync-work` before committing the version bump. This ensures that documentation in `.workaholic/specs/` and `.workaholic/terminology/` is updated to reflect the current codebase state before publishing a new release.

## Key Files

- `.claude/commands/release.md` - Release command to update
- `plugins/core/commands/sync-work.md` - Reference for the sync-work instructions

## Implementation Steps

1. Add sync-work step to `.claude/commands/release.md` before the commit step
2. Reference the sync-work.md file directly instead of using Skill tool (to work even if plugin not installed)

## Considerations

- The sync-work command may produce no changes if documentation is already up-to-date
- The release commit will now potentially include documentation updates alongside version bumps
- References sync-work.md directly to avoid dependency on plugin being installed

## Final Report

Updated `.claude/commands/release.md`:

1. Added step 9: "Sync documentation: Read `plugins/core/commands/sync-work.md` and follow its instructions to update `.workaholic/` documentation"
2. Renumbered commit step to 10 and push step to 11
3. No Skill tool dependency - works even if the core plugin is not installed
