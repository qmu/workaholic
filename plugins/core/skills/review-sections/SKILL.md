# Review Sections

Guidelines for generating story sections 4-7 (Outcome, Historical Analysis, Concerns, Successful Development Patterns) from archived tickets.

## Input

- Branch name
- List of archived ticket paths
- Carry-over verdicts file path (`/tmp/carryover-verdicts.json`, optional — empty/missing if no active carry-overs)

## Analysis Process

1. **Read all archived tickets** for the branch using Glob pattern
2. **Extract relevant content** from each ticket:
   - Overview section for accomplishments
   - Related History section for patterns
   - Considerations section for concerns
   - Final Report section (if present) for outcomes
3. **Read carry-over verdicts** from the verdicts file path. Filter to entries with `verdict: still_active`. These carry-overs were judged active by the carry-over judge subagent (the `### Judge Carry-Overs` step in `core:report`) and must be re-surfaced in this story's section 6 (Concerns).

## Section Guidelines

### Section 4: Outcome

Summarize what was accomplished across all tickets.

- List key deliverables and features implemented
- Focus on user-visible or architecturally significant changes
- Use bullet points for clarity
- Include metrics if available (files changed, tests added, etc.)

### Section 5: Historical Analysis

Extract patterns and learnings from Related History sections.

- Identify recurring themes or decisions
- Note how past decisions influenced current implementation
- Highlight any patterns that should inform future work
- If no historical context found, write "No significant historical patterns identified."

### Section 6: Concerns

Risks, trade-offs, limitations, and forward-looking suggestions discovered during implementation. Each concern is one insight expressed as a title, a description, and how to fix it — with a severity label. Emit one `###` block per concern using this exact structure (it is parsed by `extract-carryover.sh` on `/ship`):

```markdown
### <Concise title>

- **Severity:** moderate
- **Description:** <what the problem/risk is> (see [hash](url) in path/to/file.ext)
- **How to Fix:** <the concrete fix or improvement>
```

Compose the section from two sources, in this order:

1. **Carried-over concerns** — entries in the verdicts file where `verdict: still_active`. Render each as a block above; prefix the title with `(carried from PR #N)` using `origin_pr`, and preserve the carry-over's existing `severity`.
2. **New concerns** — extracted from Considerations sections of this branch's tickets.

For new concerns:

- **Severity** is a label, not a number: `urgent` (act now), `moderate` (should fix), `low` (nice-to-have). Choose based on impact and urgency; default `moderate`.
- Frame the risk and the constructive suggestion together (risk in Description, suggestion in How to Fix) — they are two angles on the same insight.
- Put the commit_hash from ticket frontmatter (if present) and the file path inside the Description.
- Keep Description and How to Fix to one paragraph each.

If both sources are empty, write "None".

### Section 7: Successful Development Patterns

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
  "concerns": "Risks, trade-offs, and forward-looking suggestions, or 'None'",
  "development_patterns": "Effective patterns or 'None'"
}
```

Each field should contain markdown-formatted content ready to be inserted into the story file.
