---
created_at: 2026-01-26T13:18:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 7185279
category: Changed
---

# Rename .work/ to .workaholic/

## Overview

Rename the `.work/` directory to `.workaholic/` throughout the codebase. The new name matches the plugin name and provides a distinctive identity for the working artifacts directory.

## Key Files

- All files referencing `.work/` directory path

## Implementation Steps

1. Rename the `.work/` directory to `.workaholic/` using `git mv`
2. Update all references from `.work/` to `.workaholic/` across the codebase
3. Update terminology/inconsistencies.md to document the migration path: `doc/` → `.work/` → `.workaholic/`

## Considerations

- Using `git mv` preserves git history
- References in archived tickets are also updated for consistency

## Final Report

Implementation deviated from original plan:

- **Change**: Removed auto-migration rule for `.work/` → `.workaholic/`
  **Reason**: User requested to only perform the actual rename without adding an auto-migration rule for future users
