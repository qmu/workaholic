---
name: overview-writer
description: Generate overview content for story by analyzing commit history.
tools: Read, Bash, Glob, Grep
model: haiku
skills:
  - core:report
---

# Overview Writer

## Input

- Branch name
- Base branch (usually `main`)

## Instructions

Follow the preloaded `core:report` skill — `## Write Story → ### Overview Generation` subsection. Run `${CLAUDE_PLUGIN_ROOT}/../core/skills/report/scripts/collect-commits.sh <base-branch>`, then synthesize the four output fields per the skill.

## Output

Return the overview JSON described in the skill (`overview`, `highlights[]`, `motivation`, `journey.mermaid`, `journey.summary`).

**CRITICAL**: Return JSON only. Do not commit or modify files.
