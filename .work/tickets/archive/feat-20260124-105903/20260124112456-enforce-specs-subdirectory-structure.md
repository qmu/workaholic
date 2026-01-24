# Enforce user-guide/ and developer-guide/ Structure in Specs

## Overview

The `/sync-src-doc` command should explicitly enforce organizing documentation under `.work/specs/user-guide/` and `.work/specs/developer-guide/` subdirectories based on the document's target audience. Currently, the frontmatter specifies `category: user | developer` but there's no instruction requiring docs to be placed in the corresponding subdirectory.

## Key Files

- `plugins/core/commands/sync-src-doc.md` - The command that needs updated instructions to enforce the directory structure

## Implementation Steps

1. Update Section 5 (Execute Spec Updates) in `sync-src-doc.md` to add a **Directory Structure** subsection before **Frontmatter**:

   ```markdown
   **Directory Structure** (required):

   All spec documents must be placed in the appropriate subdirectory based on audience:

   | Audience   | Directory                    | Content                                      |
   | ---------- | ---------------------------- | -------------------------------------------- |
   | Users      | `.work/specs/user-guide/`    | How to use: commands, workflows, setup       |
   | Developers | `.work/specs/developer-guide/` | How it works: architecture, contributing   |

   - The `category` in frontmatter must match the directory
   - Do not place documents directly in `.work/specs/` (except README.md)
   - Each subdirectory has its own README.md as an index
   ```

2. Update the frontmatter example to clarify the category-directory relationship:

   ```yaml
   category: user | developer  # Must match parent directory (user-guide or developer-guide)
   ```

3. Add a validation rule to the Critical Rules section:

   ```markdown
   - **Category matches directory** - A doc with `category: user` must be in `user-guide/`, `category: developer` in `developer-guide/`
   ```

## Considerations

- The structure already exists in the codebase, so this is about documenting and enforcing it, not creating it
- Consider whether cross-cutting documentation that serves both audiences should go in `developer-guide/` by default (since developers are a subset of users)
- The README.md files at `.work/specs/` level are exceptions to the subdirectory rule and should remain there as indexes

## Final Report

Development completed as planned.
