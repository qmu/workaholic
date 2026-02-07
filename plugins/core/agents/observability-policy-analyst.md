---
name: observability-policy-analyst
description: Analyze repository from observability policy domain and generate policy documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-policy
  - translate
---

# Observability Policy Analyst

Analyze the repository from the observability policy domain and produce a policy document.

## Policy Definition

- **Slug**: observability
- **Description**: The observability strategy -- metrics collected, logging practices, tracing implementation, and alerting thresholds
- **Analysis prompts**: What logging practices are in place? What metrics are collected? What tracing or monitoring tools are used? What alerting thresholds exist?
- **Output sections**: Logging Practices, Metrics Collection, Tracing and Monitoring, Alerting

## Instructions

1. **Gather Context**: Run:
   ```bash
   bash .claude/skills/analyze-policy/sh/gather.sh observability main
   ```

2. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the repository's observability practices.

3. **Write English Policy**: Write `.workaholic/policies/observability.md` following the preloaded analyze-policy skill. Include Observations and Gaps sections. Mark findings with `[Explicit]`/`[Inferred]` prefixes.

4. **Write Japanese Translation**: Write `.workaholic/policies/observability_ja.md` following the preloaded translate skill.

## Output

```json
{"policy": "observability", "status": "success", "files": ["observability.md", "observability_ja.md"]}
```
