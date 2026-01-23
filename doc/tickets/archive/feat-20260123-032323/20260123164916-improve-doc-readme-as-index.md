# Improve doc/README.md as Documentation Index

## Overview

The `doc/README.md` currently only indexes `doc/specs/` and `doc/tickets/`, missing the plugin documentation in `plugins/`. It should serve as a comprehensive documentation hub that links to all documentation sources in the project, including plugin READMEs. This makes it easier to discover and navigate all available documentation from a single entry point.

## Key Files

- `doc/README.md` - The main file to improve
- `plugins/core/README.md` - Plugin documentation to link
- `plugins/tdd/README.md` - Plugin documentation to link
- `doc/specs/README.md` - Already linked, but structure may need adjustment

## Implementation Steps

1. **Restructure `doc/README.md`** with clearer sections:

   - **Getting Started** - Quick links for new users (installation, first steps)
   - **Plugin Documentation** - Links to each plugin's README
   - **Specifications** - Links to `doc/specs/` (existing)
   - **Tickets** - Links to `doc/tickets/` (existing)
   - **Design Policy** - Keep the existing design policy section

2. **Add Plugins section** with direct links:
   ```markdown
   ## Plugins

   - **[Core](../plugins/core/README.md)** - Git workflow commands (`/branch`, `/commit`, `/pull-request`)
   - **[TDD](../plugins/tdd/README.md)** - Ticket-driven development (`/ticket`, `/drive`)
   ```

3. **Improve Quick Links table** to be more discoverable:
   - Group by audience (users vs developers)
   - Include plugin docs in the table
   - Consider moving Quick Links to top for faster access

4. **Update the introductory paragraph** to mention plugins:
   - Make it clear this is the documentation hub for both `doc/` and `plugins/`

5. **Verify relative links work** from `doc/README.md` to `plugins/*/README.md`:
   - Path should be `../plugins/core/README.md`

## Considerations

- Keep the Design Policy section - it's valuable context for understanding the documentation philosophy
- Don't duplicate content from plugin READMEs - just link to them
- The root `README.md` remains the GitHub landing page; `doc/README.md` is the detailed documentation hub
- Consider whether `doc/specs/` should absorb some content currently in plugin READMEs (but this may be out of scope for this ticket)

## Final Report

Development completed as planned.
