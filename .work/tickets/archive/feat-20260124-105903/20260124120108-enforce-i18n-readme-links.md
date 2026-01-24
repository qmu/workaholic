# Enforce Mirrored README Links for Bilingual Documentation

## Overview

When creating Japanese versions of documents (e.g., `commands_ja.md`), the corresponding Japanese README (`README_ja.md`) must also be updated to link to it. Currently, the rules mention "Keep translations in sync" but don't explicitly enforce that README index files must mirror each other's link structure.

The pattern should be:

- `README.md` links to `commands.md`, `workflow.md`, etc.
- `README_ja.md` links to `commands_ja.md`, `workflow_ja.md`, etc.

Without this enforcement, Japanese READMEs become orphaned indexes that don't link to their translated documents.

## Key Files

- `plugins/core/rules/general.md` - Contains Multi-Language Documentation rules that need strengthening
- `plugins/core/commands/sync-src-doc.md` - Should reference the i18n rules when updating docs

## Implementation Steps

1. Create a separate rule file `plugins/core/rules/i18n-work-docs.md` scoped to `.work/` directory:

   ```markdown
   7. **Mirror README link structure across languages** - Each language's README must link to documents in the same language:

      - If `README.md` links to `getting-started.md`, then `README_ja.md` must link to `getting-started_ja.md`
      - When creating a translated document, ALWAYS update the corresponding language README
      - The link structure must be identical between READMEs (same sections, same order)

      Example parallel structure:
   ```

   README.md: README_ja.md:

   - [Getting Started](getting-started.md) - [はじめに](getting-started_ja.md)
   - [Commands](commands.md) - [コマンド](commands_ja.md)

   ```

   ```

2. Renumber the existing rule 7 ("Respect CLAUDE.md language setting") to rule 8.

3. Add a reference in `plugins/core/commands/sync-src-doc.md` Section 7 (Update Index Files) to remind about i18n mirroring:

   ```markdown
   **Bilingual README mirroring:**

   When the project has multiple language READMEs (e.g., `README.md` and `README_ja.md`):

   - Any document added to one README must have its translation linked in the other
   - See `plugins/core/rules/general.md` for multi-language documentation policy
   ```

## Considerations

- This applies to the `.work/` directory which allows i18n content per CLAUDE.md
- The suffix-based pattern (`_ja.md`) is already established in this codebase
- Enforcement is about ensuring the agent remembers to update BOTH READMEs, not just the English one
- Could consider adding a validation step to check README link parity, but explicit instructions should suffice

## Final Report

Implementation deviated from original plan:

- **Change**: Created separate rule file `i18n-work-docs.md` instead of adding to `general.md`
  **Reason**: User requested scoping the rule specifically to `.work/` directory

- **Change**: Replaced "bilingual" with "i18n" across all active files
  **Reason**: User preferred "i18n" as the terminology (historical records kept unchanged)
