# Require README.md in Every doc/specs Subdirectory

## Overview

Every subdirectory under `doc/specs/` must have a README.md that links to all documents in that directory. This ensures discoverability and navigation. The doc-writer must keep these READMEs updated whenever documents are added, removed, or renamed.

## Key Files

- `plugins/core/rules/documentation.md` - Add requirement for subdirectory READMEs
- `plugins/core/agents/doc-writer.md` (or `plugins/tdd/agents/doc-writer.md` after move) - Add instructions to maintain subdirectory READMEs

## Implementation Steps

1. **Update `plugins/core/rules/documentation.md`** Structure section:

   - Add explicit requirement: every subdirectory in `doc/specs/` must have a README.md
   - Update Link Hierarchy to show:
     ```
     doc/specs/README.md
     ├── doc/specs/for-user/README.md
     │   ├── doc/specs/for-user/getting-started.md
     │   └── doc/specs/for-user/user-guide.md
     └── doc/specs/for-developer/README.md
         ├── doc/specs/for-developer/architecture.md
         └── doc/specs/for-developer/api.md
     ```

2. **Add README format specification** to documentation.md:

   ````markdown
   ## Subdirectory README Format

   Each subdirectory README must:

   - Have YAML frontmatter with title and description
   - List all documents in the directory with brief descriptions
   - Use relative links to documents

   Example:

   ```yaml
   ---
   title: User Documentation
   description: Documentation for end users of the project
   ---

   # User Documentation

   - [Getting Started](getting-started.md) - Installation and first steps
   - [User Guide](user-guide.md) - Complete usage instructions
   ```
   ````

3. **Update doc-writer instructions**:
   - When creating/deleting docs in a subdirectory, always update that directory's README.md
   - When auditing docs, verify all subdirectory READMEs are current
   - List missing or outdated README.md files as issues to fix

## Considerations

- README.md files provide navigation at each level of the doc hierarchy
- Keeps the "no orphan documents" constraint enforceable
- doc-writer must check README consistency as part of documentation audit
