---
created_at: 2026-01-26T13:18:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Auto-Rename .work/ to .workaholic/

## Overview

Add a rule to the core plugin that automatically renames `.work/` directory to `.workaholic/` if the migration hasn't happened yet. This ensures projects using the workaholic plugin adopt the canonical directory name.

## Key Files

- `plugins/core/rules/general.md` - Add the auto-rename rule here since it's a general housekeeping behavior

## Implementation Steps

1. Add a new rule section to `plugins/core/rules/general.md` titled "Auto-rename .work/ to .workaholic/"

2. The rule should instruct Claude to:
   - Check if `.work/` directory exists but `.workaholic/` does not
   - If so, rename `.work/` to `.workaholic/` using `git mv`
   - Commit the rename with message "Rename .work/ to .workaholic/"
   - This should happen at the start of any command that interacts with the work directory

3. The rule should NOT trigger if:
   - `.workaholic/` already exists (migration complete)
   - `.work/` doesn't exist (no migration needed)
   - Both exist (conflict - ask user)

## Considerations

- Using `git mv` preserves git history
- The commit should be automatic since this is a required migration for plugin compatibility
- Only needs to run once per project - subsequent sessions will see `.workaholic/` already exists
