# Add Performance Metrics to Branch Stories

## Overview

Add developer performance analysis to branch story files by including metrics in the YAML frontmatter and a "Performance" section in the content. Metrics include commit count, duration, velocity, and an AI-generated analysis comment. This provides valuable self-reflection data and helps developers understand their productivity patterns. The metrics also serve as cognitive investment - reducing the mental effort needed to recall "how did that branch go?"

## Key Files

- `plugins/core/commands/pull-request.md` - Update story generation section to include performance metrics
- `doc/stories/feat-20260123-032323.md` - Update existing story as an example

## Implementation Steps

1. **Update `plugins/core/commands/pull-request.md`** step 5 (Generate branch story):

   Add performance metrics to the YAML frontmatter specification:

   ```yaml
   ---
   branch: <branch-name>
   started: YYYY-MM-DD # from first ticket timestamp
   last_updated: YYYY-MM-DD # today
   tickets_completed: <count>
   # New performance metrics
   commits: <count>
   duration_hours: <number> # time between first and last commit
   velocity: <commits per hour, rounded to 1 decimal>
   ---
   ```

2. **Add instructions to calculate metrics**:

   ```bash
   # Get commit count for this branch (excluding main)
   git rev-list --count main..HEAD

   # Get first commit timestamp
   git log main..HEAD --reverse --format=%ci | head -1

   # Get last commit timestamp
   git log main..HEAD --format=%ci | head -1

   # Calculate duration in hours between first and last commit
   ```

3. **Add "Performance" section to story content structure**:

   ```markdown
   ## Performance

   **Metrics**: <commits> commits over <duration> hours (<velocity> commits/hour)

   ### Pace Analysis

   [Quantitative reflection on development pace]

   ### Decision Review

   [Qualitative analysis of decision-making - were decisions well-considered, risky, consistent? Trade-offs reasonable? Hindsight improvements?]
   ```

4. **Update `doc/stories/feat-20260123-032323.md`** as an example:

   - Add the new frontmatter properties
   - Add a Performance section with analysis
   - Calculate actual metrics from git history for this branch

5. **Update PR Description Format** to include Performance section:

   - Add Performance as a new heading in the PR body
   - Include metrics, pace analysis, and decision review from the story
   - This delivers AI performance coaching directly in the GitHub PR

6. **Add writing guidelines for Performance section**:

   - Keep analysis constructive and reflective, not judgmental
   - Note patterns that might inform future work
   - Consider context (complex features take longer, that's okay)
   - Write in third person consistent with other sections
   - Fairly analyze decision-making: reasonable, risky, consistent, well-considered?

## Considerations

- Velocity alone isn't a quality indicator - complex work may require fewer, more thoughtful commits
- The analysis should be nuanced, not just "high velocity = good"
- Duration calculation should handle edge cases (single commit = 0 hours duration)
- Metrics are for self-reflection, not comparison between developers
- AI analysis adds cognitive value by synthesizing what raw numbers mean

## Final Report

Implementation deviated from original plan:

- **Change**: Added Decision Review subsection with qualitative analysis of decision-making
  **Reason**: User requested not just quantitative metrics but also fair analysis of whether decisions were reasonable, risky, consistent, or well-considered

- **Change**: Added Performance section to PR description format
  **Reason**: User wanted AI performance coaching delivered directly in GitHub PR comments, making the feedback visible during code review
