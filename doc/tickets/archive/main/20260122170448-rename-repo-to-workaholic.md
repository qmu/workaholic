# Rename Repository References to qmu/workaholic

## Overview

Update all references from the old repository name (`qmu/cc-market-place-internal`, `cc-market-place-internal`) to the new name (`qmu/workaholic`, `workaholic`) throughout the codebase.

## Key Files

- `README.md` - Main readme with installation instructions and structure
- `CLAUDE.md` - Project instructions (has outdated structure showing `workaholic/` plugin)
- `doc/specs/GETTING_STARTED.md` - Installation instructions
- `doc/specs/FAQ.md` - Plugin installation example
- `doc/specs/TESTING.md` - Test installation commands
- `doc/specs/ARCHITECTURE.md` - Directory structure diagrams
- `doc/tickets/archive/main/CHANGELOG.md` - Commit links to GitHub

## Implementation Steps

1. **Update README.md**

   - Change title from `cc-market-place-internal` to `workaholic`
   - Update plugin add command: `qmu/cc-market-place-internal` → `qmu/workaholic`
   - Update directory structure: `cc-market-place-internal/` → `workaholic/`

2. **Update CLAUDE.md**

   - Change title from `CC Marketplace Internal` to `Workaholic`
   - Update description to reflect new name
   - Update project structure to show actual plugins (core, tdd) instead of outdated `workaholic/`

3. **Update doc/specs/GETTING_STARTED.md**

   - Update marketplace add command: `qmu/cc-market-place-internal` → `qmu/workaholic`
   - Update plugin install commands: `@qmu/cc-market-place-internal` → `@qmu/workaholic`

4. **Update doc/specs/FAQ.md**

   - Update plugin install example: `@qmu/cc-market-place-internal` → `@qmu/workaholic`

5. **Update doc/specs/TESTING.md**

   - Update plugin install commands: `@qmu/cc-market-place-internal` → `@qmu/workaholic`

6. **Update doc/specs/ARCHITECTURE.md**

   - Update directory structure: `cc-market-place-internal/` → `workaholic/`

7. **Update doc/tickets/archive/main/CHANGELOG.md**
   - Update GitHub URL: `anthropics/cc-market-place-internal` → `qmu/workaholic`

## Considerations

- The `.claude-plugin/marketplace.json` name field (`workaholic`) is a semantic identifier, not the repo name - no change needed
- Example URLs like `github.com/org/repo` in templates are placeholders and don't need updating
- The CLAUDE.md project structure is outdated (shows `workaholic/` plugin which was split into `core/` and `tdd/`) - update to match actual structure
