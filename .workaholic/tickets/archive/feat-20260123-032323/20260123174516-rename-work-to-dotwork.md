# Rename work/ to .workaholic/

## Overview

Change the working directory from `work/` to `.workaholic/` (with leading dot). The dot prefix makes it a hidden directory, keeping the project root cleaner by hiding development artifacts that users don't need to see regularly. This follows the pattern of other tooling directories like `.git/`, `.claude/`, `.vscode/`.

## Key Files

This ticket modifies the previous ticket (`20260123171203-rename-doc-to-work-directory.md`). All the same files need updating, but with `.workaholic/` instead of `work/`.

### Plugin Files

- `plugins/core/commands/pull-request.md`
- `plugins/tdd/commands/ticket.md`
- `plugins/tdd/commands/drive.md`
- `plugins/tdd/commands/sync-doc-specs.md`
- `plugins/tdd/skills/archive-ticket/SKILL.md`
- `plugins/tdd/skills/archive-ticket/scripts/archive.sh`
- `plugins/tdd/README.md`

### Other Files

- `CLAUDE.md`
- `README.md`

## Implementation Steps

1. **Update the previous ticket** (`20260123171203-rename-doc-to-work-directory.md`):

   - Change all references from `work/` to `.workaholic/`
   - Update the git mv command: `git mv doc/ .workaholic/`
   - This ticket supersedes the path choice in that ticket

2. **Or if implementing separately**, apply the same changes as the previous ticket but use `.workaholic/` everywhere:
   - `.workaholic/tickets/`
   - `.workaholic/changelogs/`
   - `.workaholic/stories/`
   - `.workaholic/specs/`

## Considerations

- Hidden directories are not shown by default in `ls` (need `ls -a`)
- IDEs typically have settings to show/hide hidden directories
- Matches convention of `.claude/`, `.git/`, `.github/`
- Files are still tracked by git (dot prefix doesn't affect git tracking)
- Some developers prefer visible directories for discoverability - this is a preference choice

## Final Report

Development completed as planned.
