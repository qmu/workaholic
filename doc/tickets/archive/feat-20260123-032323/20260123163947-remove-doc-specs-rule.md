# Remove doc-specs Rule

## Overview

Delete `plugins/tdd/rules/doc-specs.md` because path-specific rules don't work reliably when using plugins. The functionality has been fully converted into the explicit `/sync-doc-specs` command, which provides better control and clearer invocation. The rule file is now redundant and should be removed along with all references to it.

## Key Files

### File to Delete

- `plugins/tdd/rules/doc-specs.md` - The rule file to remove

### Files to Update

- `plugins/tdd/README.md` - Remove the rule from the Rules table
- `plugins/core/commands/pull-request.md` - Remove reference to "doc-specs rule (auto-loaded for that path)"
- `doc/specs/developer-guide/architecture.md` - Remove references to doc-specs rule, update documentation enforcement section
- `doc/specs/developer-guide/contributing.md` - Remove reference to doc-specs rule auto-loading
- `doc/specs/user-guide/commands.md` - Update description that mentions "doc-specs formatting rules"

## Implementation Steps

1. **Delete `plugins/tdd/rules/doc-specs.md`**

2. **Update `plugins/tdd/README.md`**:
   - Remove the entire Rules table section (no rules remain after this deletion)
   - Or if keeping the section, just remove the doc-specs.md row

3. **Update `plugins/core/commands/pull-request.md`**:
   - Change step 4 from "following the doc-specs rule (auto-loaded for that path)" to just "following `/sync-doc-specs` command guidelines"

4. **Update `doc/specs/developer-guide/architecture.md`**:
   - In the "Documentation Enforcement" section, remove mentions of the rule auto-loading
   - Update the mermaid diagram to remove "doc-specs rule enforces standards" step
   - Change "with the `doc-specs` rule enforcing standards" to explain `/sync-doc-specs` handles it
   - Remove or update "Critical Requirements" section that says "The `doc-specs` rule enforces..."
   - Remove the "Design Policy" subsection about "path-specific rule ensures..."

5. **Update `doc/specs/developer-guide/contributing.md`**:
   - Remove the paragraph about `doc-specs` rule auto-loading
   - Update to just reference `/sync-doc-specs` command

6. **Update `doc/specs/user-guide/commands.md`**:
   - Change "doc-specs formatting rules" to something like "documentation standards"

7. **Remove `rules/` directory if empty**:
   - Check if `plugins/tdd/rules/` has any other files
   - If empty after deletion, remove the directory

## Considerations

- The `/sync-doc-specs` command already contains all the formatting rules and guidelines that were in the rule file
- This is a simplification - explicit command invocation is clearer than auto-loading rules that may not trigger reliably
- Historical references in archived tickets don't need updating (they're historical records)
- The directory structure in architecture.md shows `rules/doc-specs.md` - this should be removed from the diagram

## Final Report

Development completed as planned.
