# Remove doc/specs/icebox Directory

## Overview

Remove the incorrectly located `doc/specs/icebox/` directory. The icebox location should be `doc/tickets/icebox/` as defined in the TDD plugin, not under `doc/specs/`. This cleanup removes the unnecessary directory and its `.gitkeep` file.

## Key Files

- `doc/specs/icebox/.gitkeep` - File to be deleted (incorrect location)
- `doc/tickets/icebox/` - Already correctly defined as icebox location in TDD plugin (no changes needed there)

## Implementation Steps

1. Delete `doc/specs/icebox/.gitkeep` file
2. Delete `doc/specs/icebox/` directory (will be empty after step 1)

## Considerations

- The TDD plugin already correctly references `doc/tickets/icebox/` as the icebox location
- No code changes needed in the plugin files - they already point to the correct location
- The `doc/tickets/icebox/` directory will be created automatically when needed (when a user runs `/ticket icebox <description>`)
