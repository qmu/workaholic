# Add Translation Skill

## Overview

Add a `/translate` command to the core plugin that converts English-based markdown files to another language (primarily Japanese) with consistent translation policies. This enables documentation to be maintained in multiple languages while preserving formatting, code blocks, and technical terminology.

## Key Files

- `plugins/core/commands/translate.md` - New command definition (to be created)
- `plugins/core/.claude-plugin/plugin.json` - Plugin metadata (no changes needed, commands are auto-discovered)
- `plugins/core/commands/sync-src-doc.md` - Reference for documentation processing patterns

## Implementation Steps

1. Create `plugins/core/commands/translate.md` with the following structure:
   - Frontmatter with name, description
   - Instructions for translating markdown files
   - Translation policy rules for consistency

2. Define translation policies in the command:
   - Preserve code blocks unchanged (including comments inside)
   - Preserve frontmatter keys (translate values only where appropriate)
   - Preserve markdown structure (headings, lists, tables, links)
   - Keep technical terms in English with optional Japanese annotation (e.g., "plugin（プラグイン）")
   - Translate prose content naturally, not literally
   - Preserve file references and paths unchanged

3. Define command arguments:
   - `$ARGUMENT` format: `<target-language> <file-path>`
   - Examples: `/translate ja README.md`, `/translate ja docs/guide.md`
   - Default target language: Japanese (ja) if only file path provided

4. Define output behavior:
   - Create translated file with language suffix: `README.ja.md`
   - Or create in parallel directory structure: `docs/ja/README.md`
   - Let user choose via argument or ask if ambiguous

5. Add consistency rules:
   - Keep technical terms in English for developer documentation (plugin, command, skill, rule, ticket, workflow, repository, branch, commit, merge, pull request)
   - Only translate technical terms for user-facing documentation if it improves clarity
   - Use formal/polite tone for documentation
   - Preserve original meaning over literal translation

## Considerations

- **Code block handling**: Must preserve all code, including inline code and fenced blocks
- **Link preservation**: Internal links should be updated to point to translated versions if they exist
- **Incremental updates**: Consider how to handle updates to source file (re-translate vs. merge)
- **Quality assurance**: Claude's translation quality is generally good but technical accuracy should be verified
- **Output naming convention**: Need to decide between `file.ja.md` vs `ja/file.md` patterns

## Final Report

Implementation deviated from original plan:

- **Change**: Created as `plugins/core/skills/translate/SKILL.md` with `user-invocable: false` instead of `plugins/core/commands/translate.md`
  **Reason**: User wanted translation policies as background knowledge for Claude, not a user-invocable `/translate` command

- **Change**: Technical terms (plugin, command, skill, etc.) kept in English without Japanese translations
  **Reason**: User concerned about over-translating developer documentation; technical terms should remain in English for developers
