---
created_at: 2026-01-29T01:08:25+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Flatten .workaholic/specs/ Directory Structure

## Overview

Restructure `.workaholic/` documentation by flattening the nested subdirectories. Move user-facing guides to a new `guides/` directory and move developer specs to the `specs/` root. This simplifies navigation and clarifies the distinction between user guides and technical specifications.

## Key Files

Current structure to change:
- `.workaholic/specs/user-guide/*.md` - Move to `.workaholic/guides/`
- `.workaholic/specs/developer-guide/*.md` - Move to `.workaholic/specs/` (root)
- `.workaholic/specs/README.md` - Update to reflect new structure

New structure:
- `.workaholic/guides/` - User-facing documentation (getting-started, commands, workflow)
- `.workaholic/specs/` - Technical specifications (architecture, contributing)

## Related History

The nested structure was intentionally created to separate user vs developer documentation by category. This refactoring simplifies the hierarchy.

Past tickets that touched similar areas:

- [20260124112456-enforce-specs-subdirectory-structure.md](.workaholic/tickets/archive/feat-20260124-105903/20260124112456-enforce-specs-subdirectory-structure.md) - Created the user-guide/developer-guide structure (reversing this)
- [20260127021013-extract-spec-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021013-extract-spec-skill.md) - Spec-writer skill references specs directory

## Implementation Steps

1. Create `.workaholic/guides/` directory

2. Move user-guide files to guides/:
   ```bash
   git mv .workaholic/specs/user-guide/getting-started.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/getting-started_ja.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/commands.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/commands_ja.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/workflow.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/workflow_ja.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/README.md .workaholic/guides/
   git mv .workaholic/specs/user-guide/README_ja.md .workaholic/guides/
   ```

3. Move developer-guide files to specs/ root:
   ```bash
   git mv .workaholic/specs/developer-guide/architecture.md .workaholic/specs/
   git mv .workaholic/specs/developer-guide/architecture_ja.md .workaholic/specs/
   git mv .workaholic/specs/developer-guide/contributing.md .workaholic/specs/
   git mv .workaholic/specs/developer-guide/contributing_ja.md .workaholic/specs/
   ```

4. Remove empty directories:
   ```bash
   rmdir .workaholic/specs/user-guide
   rmdir .workaholic/specs/developer-guide
   ```

5. Update `.workaholic/specs/README.md`:
   - Remove user-guide links (moved to guides/)
   - Update developer spec links to point to root files
   - Update description to focus on technical specifications

6. Update `.workaholic/specs/README_ja.md` with same changes

7. Create/update `.workaholic/guides/README.md`:
   - Keep existing user-guide content
   - Update links to use flat structure

8. Update `.workaholic/guides/README_ja.md` with same changes

9. Update `.workaholic/README.md`:
   - Change `specs/` description to "Technical specifications"
   - Add `guides/` entry for "User documentation"

10. Update `.workaholic/README_ja.md` with same changes

11. Update frontmatter `category` field in moved files:
    - Files in `specs/`: category remains `developer`
    - Files in `guides/`: category remains `user`

12. Update internal links in all files:
    - In guides/: Update cross-references if any
    - In specs/: Update links to removed subdirectory paths

13. Update `plugins/core/skills/write-spec/SKILL.md`:
    - Update any references to `user-guide/` or `developer-guide/`
    - Clarify specs/ is for technical specifications only
    - Add note that user guides go in `.workaholic/guides/`

## Considerations

- This is a breaking change for any external references to the old paths
- The `category` frontmatter field remains useful for distinguishing document types
- Spec-writer subagent needs to know specs/ is now flat
- Stories and tickets remain in their current locations (unchanged)
