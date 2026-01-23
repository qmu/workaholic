# Rename Philosophy to Design Policy

## Overview

Replace the term "Philosophy" with "Design Policy" (or "Design Decisions") throughout the codebase. "Philosophy" sounds abstract and academic; "Design Policy" is more concrete and actionable - it conveys that these are deliberate choices that should be followed, not vague principles to contemplate.

## Key Files

- `doc/README.md` - Has "## Philosophy" section
- `doc/specs/developer-guide/architecture.md` - Has "### Design Philosophy" section
- `plugins/tdd/rules/doc-specs.md` - Has "## Philosophy" section
- `plugins/tdd/commands/sync-doc-specs.md` - Has "**Philosophy**:" label in formatting rules

## Implementation Steps

1. **Update `doc/README.md`**:
   - Rename `## Philosophy` to `## Design Policy`

2. **Update `doc/specs/developer-guide/architecture.md`**:
   - Rename `### Design Philosophy` to `### Design Policy`

3. **Update `plugins/tdd/rules/doc-specs.md`**:
   - Rename `## Philosophy` to `## Design Policy`

4. **Update `plugins/tdd/commands/sync-doc-specs.md`**:
   - Rename `**Philosophy**:` to `**Design Policy**:`

5. **Update any doc templates or examples** that reference "Philosophy" as a section name

## Considerations

- This is a terminology change for clarity, not a content change
- Archived tickets don't need updating (they're historical records)
- Future documentation should use "Design Policy" or "Design Decisions" instead of "Philosophy"

## Final Report

Development completed as planned.
