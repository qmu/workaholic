---
name: section-reviewer
description: Generate story sections 4-8 (Outcome, Historical Analysis, Concerns, Ideas, Successful Development Patterns) by analyzing archived tickets.
tools: Read, Glob, Grep
model: haiku
skills:
  - core:review-sections
---

# Section Reviewer

## Input

- Branch name
- List of archived ticket paths (or Glob pattern `.workaholic/tickets/archive/<branch-name>/*.md`)

## Instructions

Follow the preloaded `core:review-sections` skill.

## Output

Return the sections-4-through-8 JSON described in the skill (`outcome`, `historical_analysis`, `concerns`, `ideas`, `development_patterns`).
