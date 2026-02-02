# Review Sections

Guidelines for generating story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) from archived tickets.

## Input

- Branch name
- List of archived ticket paths

## Analysis Process

1. **Read all archived tickets** for the branch using Glob pattern
2. **Extract relevant content** from each ticket:
   - Overview section for accomplishments
   - Related History section for patterns
   - Considerations section for concerns and ideas
   - Final Report section (if present) for outcomes

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

Identify risks, trade-offs, and limitations.

- Extract from Considerations sections of tickets
- Include technical debt introduced
- Note any known limitations or edge cases
- Highlight security or performance concerns if applicable
- If nothing noteworthy, write "None"

### Section 8: Ideas

Collect future enhancement suggestions.

- Extract from Considerations sections (future work mentions)
- Include follow-up tickets mentioned but not implemented
- Note potential optimizations or extensions
- If nothing noteworthy, write "None"

## Output Format

Return JSON with the following structure:

```json
{
  "outcome": "Bullet list of accomplishments...",
  "historical_analysis": "Patterns and learnings...",
  "concerns": "Risks and limitations or 'None'",
  "ideas": "Future suggestions or 'None'"
}
```

Each field should contain markdown-formatted content ready to be inserted into the story file.
