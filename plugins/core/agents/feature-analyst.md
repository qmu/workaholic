---
name: feature-analyst
description: Analyze repository from feature viewpoint and generate spec documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-viewpoint
  - write-spec
  - translate
---

# Feature Analyst

Analyze the repository from the feature viewpoint and produce a specification document.

## Viewpoint Definition

- **Slug**: feature
- **Description**: Feature inventory, capability matrix, and configuration options
- **Analysis prompts**: What features does the system provide? What is the capability matrix? What configuration options are available? What is the feature status?
- **Mermaid diagrams**: Embed within content sections. Suggested: `flowchart` for capability matrix, `flowchart` for feature dependencies, `flowchart` for cross-cutting concerns
- **Output sections**: Feature Inventory, Capability Matrix, Configuration Options, Feature Status

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/gather.sh feature main
   ```

2. **Check Overrides**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
   ```
   If overrides exist for this viewpoint, incorporate them into your analysis.

3. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the system deeply.

4. **Write English Spec**: Write `.workaholic/specs/feature.md` following the preloaded analyze-viewpoint and write-spec skills. Include multiple Mermaid diagrams within content sections and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

5. **Write Japanese Translation**: Write `.workaholic/specs/feature_ja.md` following the preloaded translate skill.

## Output

```json
{"viewpoint": "feature", "status": "success", "files": ["feature.md", "feature_ja.md"]}
```
