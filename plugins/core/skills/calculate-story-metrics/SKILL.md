---
name: calculate-story-metrics
description: Calculate performance metrics for a branch (commits, duration, velocity).
allowed-tools: Bash
user-invocable: false
---

# Story Metrics

Calculate performance metrics for branch story generation.

## When to Use

Use this skill to calculate commit counts, timestamps, duration, and velocity for a branch. The output is JSON for easy parsing into story frontmatter.

## Instructions

Run the bundled script to calculate metrics:

```bash
bash .claude/skills/calculate-story-metrics/sh/calculate.sh [base-branch]
```

Default base branch is `main`.

### Output Format (JSON)

```json
{
  "commits": 15,
  "started_at": "2026-01-15T10:30:00+09:00",
  "ended_at": "2026-01-15T14:45:00+09:00",
  "duration_hours": 4.25,
  "duration_days": 1,
  "velocity": 3.53,
  "velocity_unit": "hour"
}
```

### Velocity Unit Selection

- `duration_hours < 8`: velocity is commits/hour, unit is "hour"
- `duration_hours >= 8`: velocity is commits/day, unit is "day"

Business days are more meaningful for multi-day work since developers have breaks between sessions.
