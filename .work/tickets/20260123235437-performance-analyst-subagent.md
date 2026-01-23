# Create Performance Analyst Subagent

## Overview

Extract the "Decision Review" performance evaluation logic from the pull-request command into a dedicated subagent named `performance-analyst`. This subagent will evaluate the user's decision-making quality during a development branch using five structured viewpoints, providing more comprehensive and consistent feedback than the current inline approach.

## Five Evaluation Viewpoints

The performance analyst will evaluate decision-making quality across these dimensions:

1. **Consistency** - Did decisions follow established patterns? Were similar problems solved similarly? Did the approach remain stable or have unnecessary pivots?

2. **Intuitivity** - Were solutions obvious and easy to understand? Did decisions align with common expectations? Would another developer find the choices natural?

3. **Reasonability** - Were trade-offs well-considered? Were decisions proportional to the problem? Did the scope match the requirements?

4. **Agility** - How well did the developer respond to unexpected issues? Were course corrections made quickly when needed? Was feedback incorporated effectively?

5. **Density** - Was cognitive effort used efficiently? Were commits focused and minimal? Did changes accomplish goals without unnecessary complexity?

## Key Files

- `plugins/core/agents/performance-analyst.md` - New subagent to create
- `plugins/core/commands/pull-request.md` - Update to invoke the subagent instead of inline evaluation
- `plugins/core/README.md` - Document the new agent

## Implementation Steps

1. **Create agents directory in core plugin**:
   - Create `plugins/core/agents/` directory

2. **Create `plugins/core/agents/performance-analyst.md`** with this structure:
   ```markdown
   ---
   name: performance-analyst
   description: Evaluate decision-making quality across five viewpoints
   ---

   # Performance Analyst

   Analyze a development branch's decision-making quality.

   ## Input

   You will receive:
   - Branch story with motivation and journey
   - List of archived tickets with overviews and final reports
   - Git log showing commit history
   - Performance metrics (commits, duration, velocity)

   ## Evaluation Framework

   Evaluate the developer's decision-making across five dimensions. For each, provide:
   - A rating: Strong / Adequate / Needs Improvement
   - 1-2 sentences of evidence-based analysis

   ### 1. Consistency
   [Did decisions follow established patterns?...]

   ### 2. Intuitivity
   [Were solutions natural and obvious?...]

   ### 3. Reasonability
   [Were trade-offs proportional?...]

   ### 4. Agility
   [How well were pivots handled?...]

   ### 5. Density
   [Was effort focused efficiently?...]

   ## Output Format

   Return structured markdown:
   ```markdown
   ### Decision Quality Analysis

   | Dimension | Rating | Notes |
   |-----------|--------|-------|
   | Consistency | Strong/Adequate/Needs Improvement | Brief observation |
   | Intuitivity | ... | ... |
   | Reasonability | ... | ... |
   | Agility | ... | ... |
   | Density | ... | ... |

   **Strengths**: [Key positive patterns observed]

   **Areas for Improvement**: [Constructive suggestions]
   ```

   ## Guidelines

   - Be fair and constructive
   - Base ratings on evidence from tickets and commits
   - Highlight both strengths and improvement areas
   - Keep analysis concise (150-250 words total)
   ```

3. **Update `plugins/core/commands/pull-request.md`**:
   - In the story generation section (step 6), replace inline "Decision Review" with subagent invocation
   - Change from inline instructions to:
     ```markdown
     ### Decision Review
     [Invoke the performance-analyst subagent with:
     - Archived tickets for this branch
     - Git log (main..HEAD)
     - Performance metrics from frontmatter

     Include the subagent's output here.]
     ```

4. **Update `plugins/core/README.md`**:
   - Add Agents section documenting performance-analyst

5. **Update `CLAUDE.md`**:
   - Add `agents/` line to core plugin structure

## Considerations

- **Subagent invocation pattern**: The pull-request command will need to spawn this as a Task subagent. The exact invocation depends on Claude Code's subagent capabilities.
- **Backward compatibility**: The output format should remain compatible with the current PR description structure.
- **Extensibility**: The five-viewpoint framework can evolve. New viewpoints could be added later.
- **Consistency with past decision**: Agents were previously removed from core plugin. This reintroduces them with a clearer purpose - dedicated analysis rather than general exploration.
