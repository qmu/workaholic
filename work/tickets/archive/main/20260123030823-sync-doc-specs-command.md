# Add /sync-doc-specs Command to TDD Plugin

## Overview

Create a new `/sync-doc-specs` command in the TDD plugin that comprehensively updates `doc/specs/` based on the rules defined in `plugins/tdd/rules/doc-specs.md`. This command provides a standalone way to synchronize documentation with the current codebase state, independent of the PR workflow.

Currently, documentation updates happen only during `/pull-request` (step 4). Having a dedicated command allows users to update documentation at any time—useful for ad-hoc documentation cleanup, validating specs are current, or preparing documentation before a PR.

## Key Files

- `plugins/tdd/commands/sync-doc-specs.md` - New command file to create
- `plugins/tdd/.claude-plugin/plugin.json` - Plugin metadata (no changes needed, commands auto-discovered)
- `plugins/tdd/rules/doc-specs.md` - Existing rules the command must follow
- `doc/specs/` - Target directory the command updates

## Implementation Steps

1. Create `plugins/tdd/commands/sync-doc-specs.md` with the following structure:

   - YAML frontmatter with name and description
   - Instructions that reference and enforce `doc-specs.md` rules
   - Steps to audit current `doc/specs/` structure
   - Steps to identify gaps, outdated content, and orphaned documents
   - Steps to update documentation comprehensively

2. The command should perform these operations:

   - Scan the entire codebase to understand current state
   - Audit `doc/specs/` against codebase reality
   - Check all files have proper YAML frontmatter
   - Verify README.md exists in each subdirectory
   - Ensure no orphan documents (all linked from parent)
   - Update `last_updated` dates where content changed
   - Create missing documentation for undocumented features
   - Update outdated documentation to reflect current state
   - Remove documentation for features that no longer exist

3. Include validation checks:
   - Frontmatter validation (title, description, category, last_updated)
   - File naming convention (kebab-case)
   - Link integrity (no broken internal links)
   - README completeness (all docs listed in subdirectory READMEs)

## Considerations

- This command differs from PR-time documentation: it works from codebase inspection, not archived tickets
- The command should be safe to run multiple times (idempotent)
- Follow the same patterns as other TDD commands (drive.md, ticket.md)
- Only modify files within `doc/` directory (safety constraint from doc-specs rule)
- Should prompt user before making destructive changes (deleting outdated docs)

## Final Report

Development completed as planned.
