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
   author: <git user.email>
   type: enhancement | bugfix | refactoring | housekeeping
   layer: [UX, Domain, Infrastructure, DB, Config]
   effort: <time spent, e.g., 0.5h>
   ---

   # <Title>

   ## Overview
   ...
   ```

2. **Add instructions for populating frontmatter fields**:

   - `date`: Use `date +%Y-%m-%d` to get current date in ISO format
   - `author`: Use `git config user.email` to get the author email
   - `type`: Infer from context or ask user if ambiguous:
     - `enhancement` - New features or capabilities
     - `bugfix` - Fixing broken behavior
     - `refactoring` - Restructuring without changing behavior
     - `housekeeping` - Maintenance, cleanup, documentation updates
   - `layer`: Architectural layers affected (array, can specify multiple):
     - `UX` - User interface, components, styling
     - `Domain` - Business logic, models, services
     - `Infrastructure` - External integrations, APIs, networking
     - `DB` - Database, storage, migrations
     - `Config` - Configuration, build, tooling
   - `effort`: Time spent on implementation (e.g., 0.1h, 0.25h, 0.5h, 1h, 2h). Added after implementation.

3. **Update the example** in the template to show frontmatter usage

## Considerations

- **Type inference**: The command should try to infer the type from the request (e.g., "fix" → bugfix, "add" → enhancement, "refactor" → refactoring, "clean up" → housekeeping). Only ask if truly ambiguous.
- **Extensibility**: The YAML format allows easy addition of future fields (priority, labels, etc.) without breaking existing tickets.
- **Consistency with commands**: Commands like `commit.md` already use YAML frontmatter, so this brings tickets into alignment with the project's patterns.

## Final Report

Implementation deviated from original plan:

- **Change**: Author field uses email instead of name
  **Reason**: User requested email for better identification
- **Change**: Added `layer` field as YAML array
  **Reason**: User requested architectural layer tracking (UX, Domain, Infrastructure, DB, Config)
- **Change**: Added `effort` field with instructions to fill after implementation
  **Reason**: User requested time tracking for completed work
