# Dynamic Documentation with Subagent

## Overview

Replace the rigid prefixed documentation structure in `/drive` with a flexible, repository-specific approach. Documentation should be organized under `doc/specs/for-user/` and `doc/specs/for-developer/` based on the project's actual needs. A new subagent handles documentation exploration, planning, and writing. All documentation must be markdown with YAML frontmatter and use Mermaid charts for diagrams.

## Key Files

- `plugins/tdd/commands/drive.md` - Remove fixed doc list, delegate to doc-writer subagent
- `plugins/core/agents/doc-writer.md` - New subagent for documentation tasks
- `plugins/core/rules/documentation.md` - New rule file for documentation standards

## Implementation Steps

1. Create `plugins/core/rules/documentation.md` with documentation standards:

   ````markdown
   ---
   name: documentation
   description: Standards for project documentation
   ---

   # Documentation Standards

   ## File Format

   Every markdown file must have YAML frontmatter:

   ## ⁠```yaml

   title: Document Title
   description: Brief description of this document
   category: user | developer
   last_updated: YYYY-MM-DD

   ---

   ⁠```

   ## Structure

   - `doc/README.md` - Index linking to specs/ and tickets/
   - `doc/specs/README.md` - Index for all specifications
   - `doc/specs/for-user/` - User-facing documentation
   - `doc/specs/for-developer/` - Technical documentation
   - `doc/tickets/README.md` - Index for ticket system

   ## Heading Levels

   - H1 (`#`): Document title only (one per file, matches frontmatter title)
   - H2 (`##`): Major sections
   - H3 (`###`): Subsections
   - H4 (`####`): Rarely used, only for deep nesting

   ## Markdown Style

   - Use Mermaid charts for diagrams (flowcharts, sequences, architecture)
   - Write full paragraphs, not bullet-point fragments
   - Code blocks must specify language
   - Links use relative paths within doc/
   - Tables for structured data comparisons

   ## Mermaid Usage

   ⁠`mermaid
   flowchart TD
       A[Start] --> B{Decision}
       B -->|Yes| C[Action]
       B -->|No| D[End]
   ⁠`

   ## Link Hierarchy

   README.md (root)
   └── doc/README.md
   ├── doc/specs/README.md
   │ ├── doc/specs/for-user/
   │ └── doc/specs/for-developer/
   └── doc/tickets/README.md

   ## Constraints

   - No orphan documents (must be linked from parent)
   - Follow written language specified in CLAUDE.md
   - Update relevant docs with every code change
   - Keep docs close to what they document
   ````

2. Create `plugins/core/agents/doc-writer.md` subagent:

   ```yaml
   ---
   name: doc-writer
   description: Documentation specialist for exploring, planning, and writing project documentation
   tools: Read, Glob, Grep, Write, Edit
   model: sonnet
   ---
   ```

   Subagent instructions:

   - Read `plugins/core/rules/documentation.md` for standards
   - Analyze repository to determine appropriate doc structure
   - If no docs exist, enter plan mode first
   - Use Mermaid for architecture, flows, relationships
   - Write prose paragraphs, not memo-style bullets
   - Ensure YAML frontmatter on every file
   - Maintain link hierarchy from root README.md

3. Update `plugins/tdd/commands/drive.md` section 2.3:
   - Remove fixed document list
   - Delegate to `doc-writer` subagent
   - Reference documentation rule for standards

## Considerations

- Mermaid renders in GitHub, VS Code, and most markdown viewers
- YAML frontmatter enables tooling and metadata queries
- Consistent heading levels improve navigation and TOC generation
- Subagent isolation keeps main context clean during doc work
