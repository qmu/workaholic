---
name: model-analyst
description: Analyze repository from model viewpoint and generate spec documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-viewpoint
  - write-spec
  - translate
---

# Model Analyst

Analyze the repository from the model viewpoint and produce a specification document.

## Viewpoint Definition

- **Slug**: model
- **Description**: Domain concepts, relationships, and core abstractions
- **Analysis prompts**: What are the core domain entities? How do entities relate? What invariants must be maintained? What naming conventions encode domain knowledge?
- **Mermaid diagram**: `classDiagram` showing domain entities and relationships
- **Output sections**: Domain Entities, Relationships, Invariants, Naming Conventions

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/gather.sh model main
   ```

2. **Check Overrides**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
   ```
   If overrides exist for this viewpoint, incorporate them into your analysis.

3. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the system deeply.

4. **Write English Spec**: Write `.workaholic/specs/model.md` following the preloaded analyze-viewpoint and write-spec skills. Include a Mermaid `classDiagram` diagram and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

5. **Write Japanese Translation**: Write `.workaholic/specs/model_ja.md` following the preloaded translate skill.

## Output

```json
{"viewpoint": "model", "status": "success", "files": ["model.md", "model_ja.md"]}
```
