# Use Business Days for Performance Metrics

## Overview

Performance metrics currently measure raw elapsed hours (e.g., "95.7 hours"), which is misleading for multi-day work. Developers sleep, eat, and do other things - raw hours don't reflect actual working time. Metrics should use business days as the unit when work spans multiple days, making velocity measurements more meaningful.

Example of current problematic output:

```
Metrics: 131 commits over 95.7 hours (1.4 commits/hour)
```

Better alternative for multi-day work:

```
Metrics: 131 commits over 4 business days (~33 commits/day)
```

## Key Files

- `plugins/core/commands/pull-request.md` - Defines performance metrics calculation in the story generation step

## Implementation Steps

1. Update the performance metrics calculation logic in `pull-request.md`:

   - If duration < 8 hours: use hours as unit (current behavior)
   - If duration >= 8 hours: convert to business days
   - Business day calculation: count distinct calendar days with commits (not elapsed time / 24)

2. Update the frontmatter schema:

   - Keep `duration_hours` for raw data
   - Add `duration_days` when applicable
   - Change `velocity` to be context-aware (commits/hour for short work, commits/day for multi-day)

3. Update the "Metrics" output format:

   - Short work: `Metrics: X commits over Y hours (Z commits/hour)`
   - Multi-day work: `Metrics: X commits over Y business days (~Z commits/day)`

4. Update the "Pace Analysis" guidance to reference the appropriate unit

## Considerations

- "Business days with commits" is more accurate than "elapsed hours / 8" because it counts actual working days
- The 8-hour threshold is a reasonable cutoff - work under 8 hours is likely a single session
- Keep raw `duration_hours` in frontmatter for data completeness, display human-friendly format in output

## Final Report

Development completed as planned.
