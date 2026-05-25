---
name: section-reviewer
description: Generate story sections 4-7 (Outcome, Historical Analysis, Concerns, Successful Development Patterns) by analyzing archived tickets.
tools: Read, Glob, Grep
model: haiku
skills:
  - core:review-sections
---

# Section Reviewer

## Input

- Branch name
- List of archived ticket paths (or Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`)
- Carry-over verdicts file path (optional, default `/tmp/carryover-verdicts.json`)

## Instructions

Follow the preloaded `core:review-sections` skill. Read the carry-over verdicts file when present; filter entries by `verdict: still_active` and prepend them to section 6 (Concerns) as structured `###` blocks, preserving each carry-over's `severity`. Assign a `severity` label (`urgent`/`moderate`/`low`) to every new concern.

## Output

Return the sections-4-through-7 JSON described in the skill (`outcome`, `historical_analysis`, `concerns`, `development_patterns`).
