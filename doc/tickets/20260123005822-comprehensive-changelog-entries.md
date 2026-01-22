# Comprehensive Changelog Entries

## Overview

Improve the branch CHANGELOG entries to include explanatory context, not just commit message titles. Currently, entries are single-line summaries that don't provide enough detail for writing comprehensive pull request descriptions. The CHANGELOG should explain the "why" behind each change so that `/pull-request` can generate meaningful PR summaries.

## Key Files

- `plugins/tdd/skills/archive-ticket/scripts/archive.sh` - Creates CHANGELOG entries during commit
- `plugins/tdd/commands/drive.md` - Defines commit workflow and could specify richer commit messages
- `plugins/core/commands/pull-request.md` - Consumes CHANGELOG to generate PR descriptions

## Implementation Steps

1. Update `archive.sh` to accept an optional description parameter after commit message:

   ```bash
   archive.sh <ticket-path> <commit-message> <repo-url> [description] [files...]
   ```

2. Modify the CHANGELOG entry format to include description on a second line:

   ```markdown
   - Commit title ([hash](url)) - [ticket](file.md)
     Description explaining why this change was made and what problem it solves.
   ```

3. Update `drive.md` instructions (section 2.5) to:

   - Require Claude to provide both a commit title and a description
   - Description should capture the "why" from the ticket's Overview section
   - Pass description as fourth parameter to archive.sh

4. Entries can remain per-commit OR be combined when multiple commits address the same logical change - the script should handle both

## Considerations

- Keep backward compatibility: description parameter is optional, entries without description still work
- The description should be concise (1-2 sentences) but capture the motivation
- Pull-request command already expects CHANGELOG to contain the "why" - this change provides that content
- Consider: should the description come from the ticket's Overview, or should Claude write it fresh during commit?
