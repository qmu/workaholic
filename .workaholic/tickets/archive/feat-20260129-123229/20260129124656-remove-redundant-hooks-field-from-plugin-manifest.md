---
created_at: 2026-01-29T12:46:56+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: daffd75
category: Changed
---

# Remove Redundant hooks Field from Plugin Manifest

## Overview

Remove the `hooks` field from `plugins/core/.claude-plugin/plugin.json`. Claude Code automatically loads `hooks/hooks.json` from the standard location, so explicitly declaring it in the manifest causes a "Duplicate hooks file detected" error that prevents the plugin from loading.

## Key Files

- `plugins/core/.claude-plugin/plugin.json` - Remove hooks field
- `plugins/core/hooks/hooks.json` - Keep as-is (auto-loaded by Claude Code)

## Related History

This fixes an issue introduced in the ticket validation hook implementation:

- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added `hooks` field incorrectly, specifying `"hooks": "hooks/hooks.json"` which conflicts with auto-load behavior

## Implementation Steps

1. Edit `plugins/core/.claude-plugin/plugin.json`:
   - Remove the `"hooks": "hooks/hooks.json"` line (or any variation like `"./hooks/hooks.json"`)
   - Keep only: name, description, version, author fields

## Root Cause

Claude Code's plugin system has two behaviors for hooks:

1. **Auto-loading**: If `hooks/hooks.json` exists in the plugin directory, it's loaded automatically
2. **Manifest declaration**: The `hooks` field in plugin.json is for specifying *additional* hook files

When both point to the same file, Claude Code detects the duplicate and fails with:
```
Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded file
```

The original ticket's implementation plan (step 3) incorrectly added the manifest reference, unaware of the auto-load behavior.

## Considerations

- The `hooks` field in plugin.json is only needed for non-standard hook file locations
- Standard location `hooks/hooks.json` requires no manifest declaration
- This is a documentation gap in Claude Code that could benefit from clearer plugin development docs

## Final Report

### Changes Made

- Removed `"hooks": "hooks/hooks.json"` from `plugins/core/.claude-plugin/plugin.json`

### Result

Plugin now loads correctly. The hooks in `hooks/hooks.json` are auto-loaded by Claude Code without needing explicit manifest declaration.
