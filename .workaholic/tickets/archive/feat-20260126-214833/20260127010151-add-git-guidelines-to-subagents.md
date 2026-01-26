---
created_at: 2026-01-27T01:01:51+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 7933c67
category: Added
---

# Add git guidelines to subagents to prevent confirmation prompts

## Overview

Subagents spawned via the Task tool don't inherit the parent context's rules from `plugins/core/rules/general.md`. This causes them to use `git -C` variations when running git commands, which triggers confirmation prompts even with auto-accept enabled.

The rule "Never use `git -C`" exists in `general.md` but subagents don't see it. Each subagent needs explicit git command guidelines in its own instructions.

## Key Files

- `plugins/core/agents/story-writer.md` - Uses `git rev-list`, `git log`
- `plugins/core/agents/spec-writer.md` - Uses `git branch`, `git diff`, `git rev-parse`
- `plugins/core/agents/terminology-writer.md` - Uses `git branch`, `git diff`, `git rev-parse`

## Implementation Steps

1. Add a "Git Command Guidelines" section to `story-writer.md`:
   - Add after the Input section
   - Content: "Run git commands from the working directory. Never use `git -C` flag."

2. Add a "Git Command Guidelines" section to `spec-writer.md`:
   - Add after the Instructions header (before step 1)
   - Content: "Run git commands from the working directory. Never use `git -C` flag."

3. Add a "Git Command Guidelines" section to `terminology-writer.md`:
   - Add after the Instructions header (before step 1)
   - Content: "Run git commands from the working directory. Never use `git -C` flag."

## Considerations

- The `changelog-writer.md` and `pr-creator.md` don't need this change because they don't run git commands directly (changelog-writer reads frontmatter, pr-creator uses `gh` CLI)
- The `performance-analyst.md` doesn't need this because it receives data as input rather than running commands
- Keep the guideline concise - one line is enough since the agents are focused tools

## Final Report

Development completed as planned.
