# Redefine Density Metric for Semantic Expressiveness

## Overview

The "Density" dimension in the performance-analyst currently measures commit efficiency ("Were commits focused and minimal?"). This conflates two separate concerns: workflow hygiene (which belongs in a hypothetical "Efficiency" metric) and semantic expressiveness of the code itself.

The true meaning of density should be: **How much meaning is packed into the software expression?** This measures the ratio of conceptual value to textual/structural surface area - whether the code achieves its purpose with elegant economy rather than verbose sprawl.

## Key Files

- `plugins/core/agents/performance-analyst.md` - Redefine the Density dimension

## Implementation Steps

1. **Rewrite the Density section** in `plugins/core/agents/performance-analyst.md`:

   From:
   ```markdown
   ### 5. Density

   Was cognitive effort used efficiently? Were commits focused and minimal? Did changes accomplish goals without unnecessary complexity?
   ```

   To:
   ```markdown
   ### 5. Density

   Does the code express meaning economically? Is the ratio of conceptual value to textual surface area high? Does the solution achieve its purpose without verbose scaffolding, redundant abstractions, or diluted semantics?
   ```

2. **Update the Guidelines section** to clarify what Density measures:

   Add a clarifying note that Density evaluates the expressiveness of the software artifact itself, not the development process metrics (commit count, frequency, etc.). High-density code packs meaning into minimal structure. Low-density code spreads thin concepts across verbose implementations.

## Considerations

- **Separation of concerns**: Commit efficiency (how many commits, how focused) is a process/workflow metric, not a code quality metric. If process efficiency is valuable, it could become a sixth dimension called "Efficiency" in the future.
- **Evaluation difficulty**: Semantic density is harder to evaluate than commit counts. The analyst must actually read the code changes to assess expressiveness.
- **Examples for calibration**: High density = a well-named 5-line function that replaces 50 lines of repeated logic. Low density = verbose boilerplate, unnecessary indirection, or abstractions that add structure without adding meaning.

## Final Report

Development completed as planned.
