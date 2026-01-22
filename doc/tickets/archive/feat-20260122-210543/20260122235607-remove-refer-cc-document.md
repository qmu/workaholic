# Remove refer-cc-document Skill

## Overview

Remove the `refer-cc-document` skill from the core plugin. This skill is no longer needed and should be completely removed from the codebase along with all references to it.

## Key Files

- `plugins/core/skills/refer-cc-document/SKILL.md` - The skill file to be deleted
- `plugins/core/README.md` - Contains skill listing in documentation table
- `CLAUDE.md` - References skill in project structure
- `README.md` - References skill in features list
- `doc/specs/FEATURES.md` - References skill in features table
- `doc/specs/ARCHITECTURE.md` - References skill in directory structure

## Implementation Steps

1. Delete the skill directory `plugins/core/skills/refer-cc-document/`
2. Update `plugins/core/README.md` to remove the skill from the skills table
3. Update `CLAUDE.md` to remove skill reference from project structure
4. Update `README.md` to remove skill from features list
5. Update `doc/specs/FEATURES.md` to remove skill from features table
6. Update `doc/specs/ARCHITECTURE.md` to remove skill from directory structure

## Considerations

- This is a straightforward deletion with no dependencies to worry about
- The skill directory appears to be the only skill in `plugins/core/skills/` - after removal, consider whether to keep the empty `skills/` directory or remove it as well
