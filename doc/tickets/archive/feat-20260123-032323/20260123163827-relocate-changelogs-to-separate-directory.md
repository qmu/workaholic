# Relocate Changelogs to Separate Directory

## Overview

Move CHANGELOG files out of `doc/tickets/archive/<branch>/` into a dedicated `doc/changelogs/` directory with flat structure: `doc/changelogs/<branch>.md`. This separates two distinct concerns: tickets (change requests with implementation details) and changelogs (summary of changes per branch). It also makes changelogs easier to discover and browse without navigating into archive subdirectories.

## Key Files

### Files to Modify

- `plugins/tdd/skills/archive-ticket/scripts/archive.sh` - Update CHANGELOG path from `doc/tickets/archive/<branch>/CHANGELOG.md` to `doc/changelogs/<branch>.md`
- `plugins/tdd/skills/archive-ticket/SKILL.md` - Update documentation to reflect new path
- `plugins/core/commands/pull-request.md` - Update references to CHANGELOG location
- `plugins/tdd/commands/sync-doc-specs.md` - Update any CHANGELOG references
- `plugins/tdd/commands/drive.md` - Update any CHANGELOG references if present
- `doc/README.md` - Update directory structure diagram and documentation

### Files to Create

- `doc/changelogs/README.md` - Index file for changelogs directory

### Files to Migrate

- `doc/tickets/archive/*/CHANGELOG.md` → `doc/changelogs/<branch>.md`

## Implementation Steps

1. **Create `doc/changelogs/` directory structure**:

   - Create `doc/changelogs/README.md` with brief explanation and list of changelogs
   - Use descriptive summaries for each branch (not just "Feature branch") - e.g., PR title or key changes

2. **Migrate existing CHANGELOGs**:

   - Move `doc/tickets/archive/main/CHANGELOG.md` → `doc/changelogs/main.md`
   - Move `doc/tickets/archive/feat-20260122-210543/CHANGELOG.md` → `doc/changelogs/feat-20260122-210543.md`
   - Move `doc/tickets/archive/feat-20260123-005256/CHANGELOG.md` → `doc/changelogs/feat-20260123-005256.md`
   - Move `doc/tickets/archive/feat-20260123-032323/CHANGELOG.md` → `doc/changelogs/feat-20260123-032323.md`

3. **Update `plugins/tdd/skills/archive-ticket/scripts/archive.sh`**:

   - Change `CHANGELOG="${TICKET_DIR}/archive/${BRANCH}/CHANGELOG.md"` to `CHANGELOG="doc/changelogs/${BRANCH}.md"`
   - Update mkdir to create `doc/changelogs/` instead of archive subdir for changelog
   - Keep ticket archiving to `doc/tickets/archive/<branch>/` unchanged

4. **Update `plugins/tdd/skills/archive-ticket/SKILL.md`**:

   - Update documentation to mention new changelog location
   - Update any path examples

5. **Update `plugins/core/commands/pull-request.md`**:

   - Change step 3 to read from `doc/changelogs/<branch-name>.md`
   - Update step 8 to read from new location
   - Update any other CHANGELOG path references

6. **Update `plugins/tdd/commands/sync-doc-specs.md`**:

   - Update any CHANGELOG references to new location

7. **Update `doc/README.md`**:

   - Update directory structure diagram to show `doc/changelogs/`
   - Add Changelogs section explaining the directory
   - Remove CHANGELOG.md from tickets/archive structure diagram

8. **Update `doc/specs/` if needed**:
   - Check architecture.md and other specs for CHANGELOG references
   - Update paths as necessary

## Considerations

- Backward compatibility: Existing archived tickets will no longer have CHANGELOG.md siblings, but this is intentional separation
- The root `CHANGELOG.md` remains unchanged (consolidated PR changelog)
- Branch changelogs in `doc/changelogs/` are per-branch working logs
- Ticket archive directories (`doc/tickets/archive/<branch>/`) will only contain ticket .md files
- The `doc/changelogs/` directory provides a single place to browse all branch change summaries

## Final Report

Implementation deviated from original plan:

- **Change**: Added descriptive summaries for each branch in README.md instead of generic "Feature branch" labels
  **Reason**: User requested more meaningful descriptions like PR titles or key changes to make changelogs more discoverable
