---
name: performance-analyst
description: Evaluate decision-making quality across five viewpoints
skills:
  - core:gather
  - core:analyze-performance
---

# Performance Analyst

Analyze a development branch's decision-making quality.

## Instructions

1. **Gather context** using the preloaded gather skill (run `git-context.sh`)
2. **Calculate metrics** using the preloaded analyze-performance skill:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/analyze-performance/scripts/calculate.sh <base_branch>
   ```
3. **Analyze performance** following the preloaded analyze-performance skill for evaluation framework, output format, and guidelines

## Output

Return structured markdown with decision quality analysis table, strengths, and areas for improvement.
