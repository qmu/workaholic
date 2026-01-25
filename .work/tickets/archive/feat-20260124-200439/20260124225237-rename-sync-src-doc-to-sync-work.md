# Rename /sync-src-doc to /sync-work

## Overview

The command `/sync-src-doc` should be renamed to `/sync-work` because the target directory is `.work/`, not a generic "doc" folder. The current name is misleading since "doc" suggests a `docs/` directory, but the command actually syncs source code changes to the `.work/` directory (specs, terminology, etc.).

## Key Files

- `plugins/core/commands/sync-src-doc.md` - Rename to `sync-work.md`
- `plugins/core/commands/pull-request.md` - References `/sync-src-doc`
- `CLAUDE.md` - References `sync-src-doc` in project structure
- `plugins/core/README.md` - Lists the command
- `.work/specs/user-guide/commands.md` - Documents the command
- `.work/specs/user-guide/commands_ja.md` - Japanese version
- `.work/terminology/*.md` - Multiple files reference the command

## Implementation Steps

1. Rename the command file:
   ```
   plugins/core/commands/sync-src-doc.md → plugins/core/commands/sync-work.md
   ```

2. Update the frontmatter in the renamed file:
   ```yaml
   name: sync-work
   description: Sync source code changes to .work/ directory
   ```

3. Update `plugins/core/commands/pull-request.md`:
   - Change "Run `/sync-src-doc`" to "Run `/sync-work`"

4. Update `CLAUDE.md` project structure table if it lists the command

5. Update `plugins/core/README.md` command listing

6. Update `.work/specs/user-guide/commands.md` and `commands_ja.md`:
   - Rename the command section
   - Update any references

7. Search and replace in `.work/terminology/` files:
   - `sync-src-doc` → `sync-work`

8. Update `.work/stories/` files that reference the old command name

## Considerations

- This is a breaking change for anyone using the old command name
- The rename is cosmetic but improves clarity about what the command does
- All 25 files referencing the old name need to be updated
- Consider adding a note in CHANGELOG about the rename
