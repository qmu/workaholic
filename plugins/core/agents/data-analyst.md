---
name: data-analyst
description: Analyze repository from data viewpoint and generate spec documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-viewpoint
  - write-spec
  - translate
---

# Data Analyst

Analyze the repository from the data viewpoint and produce a specification document.

## Viewpoint Definition

- **Slug**: data
- **Description**: Data formats, frontmatter schemas, and file naming conventions
- **Analysis prompts**: What data formats are used? What frontmatter schemas exist? What file naming conventions are enforced? How is data validated?
- **Mermaid diagram**: `erDiagram` showing data schemas and relationships
- **Output sections**: Data Formats, Frontmatter Schemas, Naming Conventions, Validation Rules

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/gather.sh data main
   ```

2. **Check Overrides**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
   ```
   If overrides exist for this viewpoint, incorporate them into your analysis.

3. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the system deeply.

4. **Write English Spec**: Write `.workaholic/specs/data.md` following the preloaded analyze-viewpoint and write-spec skills. Include a Mermaid `erDiagram` diagram and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

5. **Write Japanese Translation**: Write `.workaholic/specs/data_ja.md` following the preloaded translate skill.

## Output

```json
{"viewpoint": "data", "status": "success", "files": ["data.md", "data_ja.md"]}
```
