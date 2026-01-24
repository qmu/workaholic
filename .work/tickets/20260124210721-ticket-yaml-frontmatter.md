# Add YAML Frontmatter to Ticket Files

## Overview

Enhance the `/ticket` command to generate ticket files with YAML frontmatter containing structured metadata. This enables better ticket management, filtering, and tracking by providing machine-readable fields for date, author, ticket type, and other relevant information.

## Key Files

- `plugins/core/commands/ticket.md` - Update ticket file structure template

## Implementation Steps

1. **Update the Ticket File Structure section** in `plugins/core/commands/ticket.md`:

   Change from:
   ```markdown
   # <Title>

   ## Overview
   ...
   ```

   To:
   ```markdown
   ---
   date: YYYY-MM-DD
   author: <git user.name>
   type: enhancement | bugfix | refactoring | housekeeping
   ---

   # <Title>

   ## Overview
   ...
   ```

2. **Add instructions for populating frontmatter fields**:

   - `date`: Use `date +%Y-%m-%d` to get current date in ISO format
   - `author`: Use `git config user.name` to get the author name
   - `type`: Infer from context or ask user if ambiguous:
     - `enhancement` - New features or capabilities
     - `bugfix` - Fixing broken behavior
     - `refactoring` - Restructuring without changing behavior
     - `housekeeping` - Maintenance, cleanup, documentation updates

3. **Update the example** in the template to show frontmatter usage

## Considerations

- **Type inference**: The command should try to infer the type from the request (e.g., "fix" → bugfix, "add" → enhancement, "refactor" → refactoring, "clean up" → housekeeping). Only ask if truly ambiguous.
- **Extensibility**: The YAML format allows easy addition of future fields (priority, labels, etc.) without breaking existing tickets.
- **Consistency with commands**: Commands like `commit.md` already use YAML frontmatter, so this brings tickets into alignment with the project's patterns.
