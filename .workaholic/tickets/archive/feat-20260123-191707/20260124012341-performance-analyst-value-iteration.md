# Shift Performance Analyst to Value Iteration Over Perfection

## Overview

Rebalance the performance-analyst agent's evaluation criteria to stop penalizing mid-stream design changes. The current framework treats changes like "renamed X to Y during the session" as evidence of "naming uncertainty" or poor upfront planning. In reality, iterating quickly and improving names/designs as understanding deepens is good development practice. The analyst should reward learning and adaptation, not punish it.

## Key Files

- `plugins/core/agents/performance-analyst.md` - The agent prompt that defines evaluation criteria

## Implementation Steps

1. **Update Consistency dimension** to clarify that pivots based on new understanding are positive:

   - Current: "Did the approach remain stable or have unnecessary pivots?"
   - Change to: "Were decisions coherent within their context? Did pivots improve the outcome rather than oscillate?"
   - The key distinction: pivots that converge toward better solutions are good; pivots that go back and forth are problematic

2. **Update Describability dimension** to remove penalty for mid-stream naming changes:

   - Current wording implies names should be right from the start
   - New framing: "Did final names land well? Were naming improvements made when better options were discovered?"
   - Reward recognizing and fixing naming issues, not penalize discovering them

3. **Update Agility dimension** to explicitly value iteration:

   - Add: "Did the developer iterate effectively, incorporating lessons learned into subsequent work?"
   - Agility should encompass both responding to external issues AND improving one's own earlier decisions

4. **Add a new guideline** in the Guidelines section:

   - "Value iteration over perfection - mid-stream improvements indicate healthy development practice, not poor planning"
   - "Penalize only oscillation (changing back and forth) not convergence (steadily improving)"

5. **Update output guidance** in the Guidelines:
   - Remove any implicit bias toward "getting it right the first time"
   - Add: "When noting design changes, distinguish between productive iteration (good) and indecisive oscillation (needs improvement)"

## Considerations

- **Balance**: We still want to catch genuinely problematic patterns like endless bikeshedding or lack of direction. The change is about rewarding convergent iteration, not excusing chaos.
- **Evidence-based**: The analyst should look at whether changes improved the outcome, not just count how many changes occurred.
- **Practical agility**: Fast "try and change" cycles are a strength in modern development. The analyst should recognize this as agility, not instability.

## Final Report

Development completed as planned.
