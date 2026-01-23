# Replace Reasonability with Describability

## Overview

Replace the "Reasonability" evaluation dimension with "Describability" in the performance-analyst subagent. Describability focuses on how well code and decisions are described—using clear, short-term naming without semantic conflicts, and maintaining extensible, consistent terminology.

## Key Files

- `plugins/core/agents/performance-analyst.md` - Update dimension 3 from Reasonability to Describability

## Implementation Steps

1. **Update dimension heading and description** in `plugins/core/agents/performance-analyst.md`:
   - Change `### 3. Reasonability` to `### 3. Describability`
   - Replace the description with:
     ```
     Were names and descriptions clear and concise? Did terminology avoid semantic conflicts? Were conventions extensible and consistent across the codebase?
     ```

2. **Update output format table**:
   - Change `| Reasonability | ... | ... |` to `| Describability | ... | ... |`

## Considerations

- This changes the evaluation criteria from "trade-off consideration" to "naming/description quality"
- The new dimension emphasizes code readability and semantic clarity over decision proportionality
- Aligns with the principle that well-described code reduces cognitive load
