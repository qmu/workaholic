---
created_at: 2026-01-27T01:36:09+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: 13101ad
category: Changed
---

# Embed git guidelines directly in each subagent definition

## Overview

The `plugins/core/rules/subagents.md` approach doesn't work because subagents don't inherit rules - rules apply to file paths during conversation, not to subagent prompts.

Solution: Write the git rule duplicated in each subagent definition file. Yes, it's duplication, but there's no include mechanism for agents.

## Key Files

- `plugins/core/rules/subagents.md` - DELETE: This rule doesn't work for subagents
- `plugins/core/agents/story-writer.md` - Add CRITICAL git guidelines (uses Bash)
- `plugins/core/agents/spec-writer.md` - Add CRITICAL git guidelines (uses Bash)
- `plugins/core/agents/terms-writer.md` - Add CRITICAL git guidelines (uses Bash)
- `plugins/core/agents/changelog-writer.md` - Add CRITICAL git guidelines (uses Bash)
- `plugins/core/agents/pr-creator.md` - Add CRITICAL git guidelines (uses Bash)

## Implementation Steps

1. Delete `plugins/core/rules/subagents.md` (it doesn't work for subagents)

2. Add the following section to each agent that has `Bash` in its tools list. Place it immediately after the frontmatter, before any other content:

   ```markdown
   ## CRITICAL: Git Command Format

   **NEVER use `git -C <path>` flag.** Always run git commands directly:

   - WRONG: `git -C /path/to/repo rev-list --count main..HEAD`
   - RIGHT: `git rev-list --count main..HEAD`

   The `-C` flag causes permission prompts and must not be used.
   ```

3. Update these agent files:
   - `story-writer.md` - Add after `# Story Writer` heading
   - `spec-writer.md` - Add after `# Spec Writer` heading
   - `terms-writer.md` - Add after `# Terms Writer` heading
   - `changelog-writer.md` - Add after `# Changelog Writer` heading
   - `pr-creator.md` - Add after `# PR Creator` heading

## Considerations

- This is intentional duplication - there's no way to share content across agent files
- The `performance-analyst.md` doesn't use Bash tool, so it doesn't need this
- Future agents that use Bash must include this section manually
- The strong "CRITICAL" language and WRONG/RIGHT examples are essential to override default behavior

## Final Report

Development completed as planned.
