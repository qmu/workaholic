# Rewrite sync-doc-specs Command

## Overview

Convert the passive `doc-specs.md` rule file into an actionable `/sync-doc-specs` command. The current command is a thin 5-line wrapper that says "enter plan mode and follow doc-specs rules". Instead, it should be a comprehensive, step-by-step command that Claude can execute directly without needing to reference external rules.

## Key Files

- `plugins/tdd/commands/sync-doc-specs.md` - Rewrite this command with full instructions
- `plugins/tdd/rules/doc-specs.md` - Source material to extract and transform (keep as reference rule)

## Implementation Steps

1. **Rewrite `plugins/tdd/commands/sync-doc-specs.md`** with these sections:

   ### Frontmatter

   Keep existing name/description

   ### Instructions

   Structure as actionable steps:

   **Step 1: Gather Context**

   - Read archived tickets from `doc/tickets/archive/<current-branch>/`
   - Extract what changed (from Implementation Steps) and why (from Overview)
   - If no archived tickets, explore codebase changes via git diff against main

   **Step 2: Audit Current Documentation**

   - List all files in `doc/specs/`
   - Read each document to understand current state
   - Identify gaps, outdated content, or missing docs

   **Step 3: Plan Documentation Updates**

   - Determine which docs need updates based on changes
   - Identify new docs needed for new concepts
   - Identify docs to delete if features removed
   - Plan README updates for any added/removed docs

   **Step 4: Execute Updates**
   For each file, follow these rules:

   - **Frontmatter**: Every file needs YAML with title, description, category, last_updated
   - **Naming**: kebab-case for all files except README.md
   - **Headings**: H1 for title only, H2 for sections, H3 for subsections
   - **Content**: Full paragraphs (not bullet fragments), code blocks with language, relative links
   - **Philosophy**: Rewrite to reflect present state, don't append historical changes

   **Step 5: Update Index Files**

   - Update `doc/specs/README.md` if top-level docs changed
   - Update subdirectory READMEs when adding/removing docs
   - Ensure no orphan documents (all linked from parent)

   ### File Format Reference

   Include the frontmatter template:

   ```yaml
   ---
   title: Document Title
   description: Brief description
   category: user | developer
   last_updated: YYYY-MM-DD
   ---
   ```

   ### Critical Rules

   - "No updates needed" is almost always wrong - re-analyze
   - Only delete files within `doc/` directory
   - Every ticket should affect docs somehow

2. **Keep `rules/doc-specs.md`** as a passive reference for when Claude is editing files in `doc/specs/` outside of this command

## Considerations

- The command should be self-contained - Claude shouldn't need to read the rules file
- Follow the same structural pattern as `drive.md` and `commit.md` (numbered steps with clear actions)
- The rules file can remain as a fallback for ad-hoc doc editing

## Final Report

Development completed as planned.
