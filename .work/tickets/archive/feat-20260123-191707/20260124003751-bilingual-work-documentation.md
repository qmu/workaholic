# Add Japanese Translations for .work/ Documentation

## Overview

Create Japanese translation files (`*_ja.md`) for all documentation in the `.work/` directory, following the multi-language documentation policy with separate files using the `_ja` suffix pattern. This implements the bilingual support declared in CLAUDE.md for the `.work/` directory.

## Key Files

**Files to translate (16 total):**

### Root (1 file)
- `.work/README.md` → `.work/README_ja.md`

### Specs (8 files)
- `.work/specs/README.md` → `.work/specs/README_ja.md`
- `.work/specs/user-guide/README.md` → `.work/specs/user-guide/README_ja.md`
- `.work/specs/user-guide/getting-started.md` → `.work/specs/user-guide/getting-started_ja.md`
- `.work/specs/user-guide/commands.md` → `.work/specs/user-guide/commands_ja.md`
- `.work/specs/user-guide/workflow.md` → `.work/specs/user-guide/workflow_ja.md`
- `.work/specs/developer-guide/README.md` → `.work/specs/developer-guide/README_ja.md`
- `.work/specs/developer-guide/architecture.md` → `.work/specs/developer-guide/architecture_ja.md`
- `.work/specs/developer-guide/contributing.md` → `.work/specs/developer-guide/contributing_ja.md`

### Stories (2 files)
- `.work/stories/README.md` → `.work/stories/README_ja.md`
- `.work/stories/feat-20260123-032323.md` → `.work/stories/feat-20260123-032323_ja.md`

### Terminology (6 files)
- `.work/terminology/README.md` → `.work/terminology/README_ja.md`
- `.work/terminology/core-concepts.md` → `.work/terminology/core-concepts_ja.md`
- `.work/terminology/artifacts.md` → `.work/terminology/artifacts_ja.md`
- `.work/terminology/workflow-terms.md` → `.work/terminology/workflow-terms_ja.md`
- `.work/terminology/file-conventions.md` → `.work/terminology/file-conventions_ja.md`
- `.work/terminology/inconsistencies.md` → `.work/terminology/inconsistencies_ja.md`

**Excluded from translation:**
- Changelogs - Historical commit records don't benefit from translation
- Tickets - Working artifacts that are consumed during development

## Final Report

Implementation deviated from original plan:

- **Change**: Reduced scope from 24 files to 17 files
  **Reason**: User requested to exclude changelogs and tickets from translation, as historical commit records and working artifacts don't benefit from translation

## Implementation Steps

1. **Add language navigation badges to existing English files**
   - Add `[English](README.md) | [日本語](README_ja.md)` badges at the top of each English file
   - Use relative paths appropriate for each file location

2. **Create Japanese translations for each category in order:**
   - Start with root README and READMEs of each subdirectory (index files)
   - Then translate specs/ (user-guide first, then developer-guide)
   - Then translate terminology/ (core reference documentation)
   - Then translate changelogs/ and stories/
   - Finally translate tickets/README.md

3. **For each translation:**
   - Preserve the same structure and formatting as the English original
   - Preserve code blocks, file paths, and technical terms in their original form
   - Translate prose content, headings, and descriptions to natural Japanese
   - Add language navigation badge at the top linking back to English version
   - Keep frontmatter fields in English (title, description, category, etc.)

4. **Update `.work/README.md` and subdirectory READMEs**
   - Add links to Japanese versions in the index listings where applicable

## Considerations

- **Technical terms**: Keep English terms like "ticket", "spec", "changelog", "commit" as-is or use katakana (チケット, スペック, etc.) based on common usage
- **File paths and code**: Never translate file paths, command names, or code examples
- **Frontmatter**: Keep YAML frontmatter keys in English for consistency
- **Future maintenance**: When English docs are updated, Japanese translations should be updated to match (this is a manual process)
- **Scope boundary**: This ticket only covers existing files in `.work/`. Archive files and queued tickets are not translated.
- **Large scope**: This is a substantial translation task. Consider committing in logical groups (by directory) rather than all at once.
