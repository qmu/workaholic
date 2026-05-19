# Review Sections

Guidelines for generating story sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns) from archived tickets.

## Input

- Branch name
- List of archived ticket paths
- Carry-over verdicts file path (`/tmp/carryover-verdicts.json`, optional — empty/missing if no active carry-overs)

## Analysis Process

1. **Read all archived tickets** for the branch using Glob pattern
2. **Extract relevant content** from each ticket:
   - Overview section for accomplishments
   - Related History section for patterns
   - Considerations section for concerns and ideas
   - Final Report section (if present) for outcomes
3. **Read carry-over verdicts** from the verdicts file path. Filter to entries with `verdict: still_active`. These carry-overs were judged active by `work:carryover-judge` and must be re-surfaced in this story's sections 6 and 7.

## Section Guidelines

### Section 5: Outcome

Summarize what was accomplished across all tickets.

- List key deliverables and features implemented
- Focus on user-visible or architecturally significant changes
- Use bullet points for clarity
- Include metrics if available (files changed, tests added, etc.)

### Section 6: Historical Analysis

Extract patterns and learnings from Related History sections.

- Identify recurring themes or decisions
- Note how past decisions influenced current implementation
- Highlight any patterns that should inform future work
- If no historical context found, write "No significant historical patterns identified."

### Section 7: Concerns

Identify risks, trade-offs, and limitations with identifiable references. Compose the section from two sources, in this order:

1. **Carried-over concerns** — entries in the verdicts file where `verdict: still_active` and `kind: concern`. Prefix each with `(carried from PR #N)` using `origin_pr` from the carry-over.
2. **New concerns** — extracted from Considerations sections of this branch's tickets.

For new concerns:

- Extract from Considerations sections of tickets
- Include commit_hash from ticket frontmatter (if present) for each concern
- Include file paths mentioned in the Considerations section
- Include technical debt introduced
- Note any known limitations or edge cases
- Highlight security or performance concerns if applicable
- Format: `<description> (see [hash](url) in path/to/file.ext)`

If both sources are empty, write "None".

### Section 8: Ideas

Collect future enhancement suggestions. Compose the section from two sources, in this order:

1. **Carried-over ideas** — entries in the verdicts file where `verdict: still_active` and `kind: idea`. Prefix each with `(carried from PR #N)` using `origin_pr` from the carry-over.
2. **New ideas** — extracted from Considerations sections (future work mentions).

For new ideas:

- Extract from Considerations sections (future work mentions)
- Include follow-up tickets mentioned but not implemented
- Note potential optimizations or extensions

If both sources are empty, write "None".

### Section 8: Successful Development Patterns

Capture effective patterns discovered during this branch's development.

- Extract positive observations from ticket Considerations sections
- Extract "what went well" insights from Final Report sections
- Identify effective approaches from Implementation Steps that proved successful
- Look for recurring successful strategies across multiple tickets
- Categories to consider:
  - Architectural decisions that worked well
  - Testing strategies that caught issues
  - Refactoring approaches that improved code quality
  - Collaboration or workflow patterns that were effective
  - Tooling or automation choices that saved effort
- Each pattern should include reasoning for why it worked
- If no noteworthy patterns, write "None"

## Output Format

Return JSON with the following structure:

```json
{
  "outcome": "Bullet list of accomplishments...",
  "historical_analysis": "Patterns and learnings...",
  "concerns": "Risks and limitations or 'None'",
  "ideas": "Future suggestions or 'None'",
  "development_patterns": "Effective patterns or 'None'"
}
```

Each field should contain markdown-formatted content ready to be inserted into the story file.
