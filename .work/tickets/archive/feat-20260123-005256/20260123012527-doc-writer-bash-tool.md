# Add Bash Tool to doc-writer for File/Directory Removal

## Overview

The doc-writer agent needs the ability to delete outdated documentation files and empty directories. Currently it only has `Read, Glob, Grep, Write, Edit` tools. Adding `Bash` allows it to run `rm` for files and `rmdir` for directories when cleaning up obsolete documentation.

## Key Files

- `plugins/core/agents/doc-writer.md` - Add Bash to tools list (will be in `plugins/tdd/agents/` after move ticket)

## Implementation Steps

1. Update the frontmatter `tools` line to include Bash:

   ```yaml
   tools: Read, Glob, Grep, Write, Edit, Bash
   ```

2. Add instructions for when to use Bash:
   - Use `rm` to delete outdated documentation files
   - Use `rmdir` to remove empty documentation directories
   - Only delete files within `doc/` directory (safety constraint)

## Considerations

- Bash is a powerful tool - instructions should limit its use to documentation cleanup only
- Should only delete within `doc/` to prevent accidental deletion of source code
- This enables the "Delete outdated or invalid documentation" requirement from drive.md step 2.3
