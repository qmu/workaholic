---
name: component-analyst
description: Analyze repository from component viewpoint and generate spec documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-viewpoint
  - write-spec
  - translate
---

# Component Analyst

Analyze the repository from the component viewpoint and produce a specification document.

## Viewpoint Definition

- **Slug**: component
- **Description**: Internal structure, module boundaries, and skill/agent/command decomposition
- **Analysis prompts**: What are the module boundaries? How are responsibilities distributed? What are the dependency directions? What design patterns are used?
- **Mermaid diagram**: `flowchart` showing component hierarchy and dependency directions
- **Output sections**: Module Boundaries, Responsibility Distribution, Dependency Graph, Design Patterns

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/gather.sh component main
   ```

2. **Check Overrides**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
   ```
   If overrides exist for this viewpoint, incorporate them into your analysis.

3. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the system deeply.

4. **Write English Spec**: Write `.workaholic/specs/component.md` following the preloaded analyze-viewpoint and write-spec skills. Include a Mermaid `flowchart` diagram and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

5. **Write Japanese Translation**: Write `.workaholic/specs/component_ja.md` following the preloaded translate skill.

## Output

```json
{"viewpoint": "component", "status": "success", "files": ["component.md", "component_ja.md"]}
```
