# Add commit_hash to Doc Specs Frontmatter

## Overview

Add a `commit_hash` field to the YAML frontmatter in `doc/specs/` files. This enables AI to understand the state of documentation at a specific point in git history, making it possible to discover what changed between then and now by comparing commits.

## Key Files

- `plugins/tdd/rules/doc-specs.md` - Update frontmatter specification to include commit_hash
- `plugins/tdd/commands/sync-doc-specs.md` - Update command to set commit_hash when updating docs
- `doc/specs/**/*.md` - All existing spec files need commit_hash added

## Implementation Steps

1. **Update `plugins/tdd/rules/doc-specs.md`** frontmatter specification:
   ```yaml
   ---
   title: Document Title
   description: Brief description of this document
   category: user | developer
   last_updated: YYYY-MM-DD
   commit_hash: <short-hash>
   ---
   ```
   - Use short hash (7 chars) for readability: `git rev-parse --short HEAD`
   - Document that this represents the commit where the doc was last meaningfully updated

2. **Update `plugins/tdd/commands/sync-doc-specs.md`** to include instruction:
   - When updating a doc file, also update `commit_hash` to current HEAD
   - Run `git rev-parse --short HEAD` to get the hash

3. **Update all existing `doc/specs/**/*.md` files** with current commit hash:
   - Add `commit_hash: <current-short-hash>` to each file's frontmatter

## Considerations

- Use short hash (7 chars) for readability while still being unique enough
- The hash represents "last meaningful update" - tied to `last_updated` date
- AI can later run `git diff <commit_hash>..HEAD -- <file>` to see changes since that point
- This creates a machine-readable audit trail for documentation evolution
