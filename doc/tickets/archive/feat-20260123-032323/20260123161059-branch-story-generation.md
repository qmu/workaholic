# Generate Branch Story for Pull Requests

## Overview

Create a narrative "story" document that captures the developer's journey through a branch. Unlike the CHANGELOG (which lists individual changes) or individual tickets (which describe specific implementations), the story synthesizes the entire branch into a coherent narrative: what motivated this work, what problems arose, and how decisions were made.

This story file (`doc/stories/<branch-name>.md`) is generated during `/pull-request` and its content is included in the PR description, giving reviewers a high-level understanding of the work before diving into individual changes.

## Key Files

- `plugins/core/commands/pull-request.md` - Add story generation step before PR creation
- `doc/stories/` - New directory for story files (created automatically)

## Implementation Steps

1. **Update `plugins/core/commands/pull-request.md`** to add a new step after documentation updates:

   ### Generate Branch Story

   Create `doc/stories/<branch-name>.md` by synthesizing archived tickets:

   ```bash
   # Read all archived tickets for this branch
   ls -1 doc/tickets/archive/<branch-name>/*.md 2>/dev/null | grep -v CHANGELOG
   ```

   For each ticket, extract:
   - **Overview section**: The "why" - motivation and problem description
   - **Final Report section**: The "how" - what actually happened, including deviations

   **Story file format:**

   ```yaml
   ---
   branch: <branch-name>
   started: YYYY-MM-DD
   last_updated: YYYY-MM-DD
   tickets_completed: <count>
   ---
   ```

   ```markdown
   # Story: <Branch Name>

   ## Motivation

   [Synthesize the "why" from ticket Overviews. What problem or opportunity started this work? Write as a narrative, not a list.]

   ## Journey

   [Describe the progression of work. What was planned? What unexpected challenges arose? How were decisions made? Draw from Final Reports to capture deviations and learnings.]

   ## Outcome

   [Summarize what was accomplished. Reference key tickets for details.]
   ```

   **Writing guidelines:**
   - Write in third person ("The developer discovered..." not "I discovered...")
   - Connect tickets into a narrative arc, not a list
   - Highlight decision points and trade-offs
   - Keep it concise (aim for 200-400 words)

2. **Update PR description format** in `pull-request.md`:

   Add a new section that includes the story:

   ```markdown
   ## Story

   [Include Motivation and Journey sections from doc/stories/<branch>.md]
   ```

   The PR format becomes:
   - Refs #issue
   - Summary (list of changes from CHANGELOG)
   - Story (narrative from story file)
   - Changes (detailed explanations)
   - Notes

3. **Handle story updates**:
   - If story file exists, update `last_updated` and regenerate content
   - Preserve any manual edits by re-reading and merging (or warn user)

## Considerations

- Stories are generated, not handwritten, to reduce friction
- The narrative format helps reviewers understand context quickly
- Stories complement but don't replace CHANGELOG (different purposes)
- `started` date comes from first ticket timestamp in the branch
- Story generation happens after all tickets are archived, so it has complete context
- Consider story length - too long reduces readability; too short lacks value

## Final Report

Development completed as planned.
