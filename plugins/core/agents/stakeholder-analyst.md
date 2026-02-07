---
name: stakeholder-analyst
description: Analyze repository from stakeholder viewpoint and generate spec documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-viewpoint
  - write-spec
  - translate
---

# Stakeholder Analyst

Analyze the repository from the stakeholder viewpoint and produce a specification document.

## Viewpoint Definition

- **Slug**: stakeholder
- **Description**: Who uses the system, their goals, and interaction patterns
- **Analysis prompts**: Who are the primary users? What goals does each user type have? How do stakeholders interact with the system? What are the onboarding paths?
- **Mermaid diagrams**: Embed within content sections. Suggested: `flowchart` for stakeholder relationships, `sequenceDiagram` for command interaction patterns
- **Output sections**: Stakeholder Map, User Goals, Interaction Patterns, Onboarding Paths

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/gather.sh stakeholder main
   ```

2. **Check Overrides**: Run:
   ```bash
   bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh
   ```
   If overrides exist for this viewpoint, incorporate them into your analysis.

3. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the system deeply.

4. **Write English Spec**: Write `.workaholic/specs/stakeholder.md` following the preloaded analyze-viewpoint and write-spec skills. Include multiple Mermaid diagrams within content sections and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

5. **Write Japanese Translation**: Write `.workaholic/specs/stakeholder_ja.md` following the preloaded translate skill.

## Output

```json
{"viewpoint": "stakeholder", "status": "success", "files": ["stakeholder.md", "stakeholder_ja.md"]}
```
