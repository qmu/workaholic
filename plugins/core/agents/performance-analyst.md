---
name: performance-analyst
description: Evaluate decision-making quality across five viewpoints
skills:
  - gather-git-context
  - analyze-performance
---

# Performance Analyst

Analyze a development branch's decision-making quality.

## Instructions

1. **Gather context** using the preloaded gather-git-context skill
2. **Calculate metrics** using the preloaded analyze-performance skill:
   ```bash
   bash .claude/skills/analyze-performance/sh/calculate.sh <base_branch>
   ```
3. **Analyze performance** following the preloaded analyze-performance skill for evaluation framework, output format, and guidelines

## Output

Return structured markdown with decision quality analysis table, strengths, and areas for improvement.
