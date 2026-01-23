# Rename doc/ to work/ Directory

## Overview

Rename the documentation directory from `doc/` to `work/` as the new default, and make the directory name configurable. The name "work" better reflects the purpose - it contains working artifacts (tickets, changelogs, stories, specs) that support the development process, not just documentation. This change requires moving all files and updating all references in plugins.

## Key Files

### Directory to Rename

- `doc/` → `work/` (entire directory tree)

### Plugin Files to Update

- `plugins/core/commands/pull-request.md` - Multiple `doc/` references
- `plugins/tdd/commands/ticket.md` - `doc/tickets/` references
- `plugins/tdd/commands/drive.md` - `doc/tickets/` references
- `plugins/tdd/commands/sync-doc-specs.md` - `doc/specs/` references
- `plugins/tdd/skills/archive-ticket/SKILL.md` - `doc/tickets/` references
- `plugins/tdd/skills/archive-ticket/scripts/archive.sh` - `doc/tickets/` and `doc/changelogs/` references
- `plugins/tdd/README.md` - `doc/tickets/` references

### Other Files to Update

- `CLAUDE.md` - Project structure mentions
- `README.md` - Workflow examples

## Implementation Steps

1. **Move the directory**:
   ```bash
   git mv doc/ work/
   ```

2. **Update `plugins/tdd/commands/ticket.md`**:
   - Replace all `doc/tickets/` with `work/tickets/`

3. **Update `plugins/tdd/commands/drive.md`**:
   - Replace all `doc/tickets/` with `work/tickets/`

4. **Update `plugins/tdd/commands/sync-doc-specs.md`**:
   - Replace all `doc/specs/` with `work/specs/`
   - Replace all `doc/tickets/` with `work/tickets/`
   - Consider renaming command from `sync-doc-specs` to `sync-specs` (separate ticket if desired)

5. **Update `plugins/core/commands/pull-request.md`**:
   - Replace all `doc/changelogs/` with `work/changelogs/`
   - Replace all `doc/tickets/` with `work/tickets/`
   - Replace all `doc/specs/` with `work/specs/`
   - Replace all `doc/stories/` with `work/stories/`

6. **Update `plugins/tdd/skills/archive-ticket/scripts/archive.sh`**:
   - Replace `doc/tickets/` with `work/tickets/`
   - Replace `doc/changelogs/` with `work/changelogs/`

7. **Update `plugins/tdd/skills/archive-ticket/SKILL.md`**:
   - Replace all `doc/tickets/` with `work/tickets/`

8. **Update `plugins/tdd/README.md`**:
   - Replace all `doc/tickets/` with `work/tickets/`

9. **Update `CLAUDE.md`**:
   - Update project structure to show `work/` instead of `doc/`

10. **Update `README.md`**:
    - Update workflow examples to use `work/tickets/`

11. **Update internal references within `work/`**:
    - `work/README.md` - Update any self-references
    - `work/specs/developer-guide/architecture.md` - Update directory diagrams
    - Other spec files that reference `doc/`

## Considerations

- This is a breaking change for anyone following current documentation
- The git history will show a rename, preserving file history
- All queued tickets in `doc/tickets/` will move to `work/tickets/`
- The `sync-doc-specs` command name becomes slightly misleading (`sync-specs` would be cleaner, but that's a separate change)
- Configuration for custom directory name is deferred - this ticket just establishes `work/` as the new default
- Internal links within the `work/` directory need updating (relative links should still work after move)
