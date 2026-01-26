# Merge Core and TDD Plugins

## Overview

Consolidate the `core` and `tdd` plugins into a single unified `core` plugin. This simplifies the marketplace by providing a single, comprehensive development workflow plugin instead of requiring users to install two separate plugins that are typically used together.

## Key Files

**To merge into core:**

- `plugins/tdd/commands/ticket.md` → `plugins/core/commands/ticket.md`
- `plugins/tdd/commands/drive.md` → `plugins/core/commands/drive.md`
- `plugins/tdd/commands/sync-src-doc.md` → `plugins/core/commands/sync-src-doc.md`
- `plugins/tdd/skills/archive-ticket/` → `plugins/core/skills/archive-ticket/`

**To update:**

- `plugins/core/.claude-plugin/plugin.json` - Update description
- `plugins/core/README.md` - Merge documentation from both plugins
- `.claude-plugin/marketplace.json` - Remove tdd plugin entry
- `CLAUDE.md` - Update project structure

**To delete:**

- `plugins/tdd/` - Entire directory after merge

## Implementation Steps

1. **Move TDD commands to core**:

   - Copy `plugins/tdd/commands/ticket.md` to `plugins/core/commands/`
   - Copy `plugins/tdd/commands/drive.md` to `plugins/core/commands/`
   - Copy `plugins/tdd/commands/sync-src-doc.md` to `plugins/core/commands/`

2. **Move TDD skills to core**:

   - Create `plugins/core/skills/` directory
   - Copy `plugins/tdd/skills/archive-ticket/` to `plugins/core/skills/`

3. **Update core plugin.json**:

   - Update description to reflect combined functionality:
     ```json
     "description": "Core development workflow: branch, commit, pull-request, ticket-driven development"
     ```

4. **Merge README documentation**:

   - Update `plugins/core/README.md` to include:
     - Existing Commands table (branch, commit, pull-request)
     - TDD Commands (ticket, drive, sync-src-doc)
     - Skills section (archive-ticket)
     - "Why Documentation?" philosophy section from TDD
     - Workflow section from TDD
     - Ticket Storage section from TDD

5. **Update marketplace.json**:

   - Remove the tdd plugin entry from plugins array
   - Update core plugin description

6. **Update CLAUDE.md**:

   - Update project structure to show merged layout:
     ```
     core/
       .claude-plugin/
       agents/
       commands/    # branch, commit, pull-request, ticket, drive, sync-src-doc
       rules/
       skills/      # archive-ticket
     ```
   - Remove tdd/ from structure
   - Update Commands table to show all commands under unified workflow

7. **Delete tdd plugin**:
   - Remove `plugins/tdd/` directory entirely

## Considerations

- **Breaking change for users**: Users who have `"plugins": ["tdd"]` in their config will need to update to `"plugins": ["core"]`. Document this in CHANGELOG.
- **Archive script path**: The archive script path changes from `plugins/tdd/skills/...` to `plugins/core/skills/...`. Update any references in drive.md.
- **Version**: Keep version at 1.0.15 - the merge is a structural change, not a feature addition.

## Final Report

Development completed as planned.
