# Add Development Routine Section to README

## Overview

Add a new "Development Routine" section to README.md that explains how the workaholic plugin workflow differs from traditional GitHub issue-driven development. This section will highlight the local-first, AI-assisted approach that minimizes context switching and GitHub dependency to maximize development velocity with Claude Code.

## Key Files

- `README.md` - Main documentation file where the new section will be added

## Implementation Steps

1. Add a new "## Development Routine" section after the "## Workflow" section in README.md

2. Include the following content areas:

   - **Philosophy**: Explain the local-first approach vs GitHub issue-driven
   - **Key Differences**: Contrast with traditional workflow
   - **Benefits**: Speed, reduced context switching, AI-native workflow

3. Structure the comparison to highlight:

   - Traditional: Create GitHub issue → Discuss → Assign → Branch → Code → PR → Review
   - Workaholic: `/ticket` → `/drive` → `/pull-request` (all in terminal, all with Claude)

4. Emphasize key points:
   - Tickets are local markdown files, not GitHub issues
   - Claude Code explores codebase and writes implementation specs
   - Implementation happens immediately after spec approval
   - GitHub is only used at the end for PR/review, not for planning
   - No waiting for issue triage, assignment, or discussion threads

## Considerations

- Keep the tone practical and focused on developer experience
- Don't criticize GitHub issues - position workaholic as an alternative for rapid prototyping and solo/small team workflows
- Include a note that this workflow works best when the developer has clear goals and doesn't need extensive stakeholder discussion before coding
