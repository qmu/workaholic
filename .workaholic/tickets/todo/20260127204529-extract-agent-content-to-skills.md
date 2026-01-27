---
created_at: 2026-01-27T20:45:29+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Extract agent content to preloaded skills

## Overview

The agent files in `plugins/core/agents/` contain substantial template content and detailed instructions that bloat their size. According to Claude Code documentation, skills can be preloaded into subagents via the `skills:` frontmatter field, injecting the full skill content into the agent's context at startup.

This refactoring extracts the "what to do" instructions into skills while keeping agents thin - focused only on "when to use" (description) and "what tools" (frontmatter). The goal is not a simple copy-paste but a reorganization that:

1. Makes agents declarative (metadata only, ~20-30 lines each)
2. Makes skills comprehensive (full instructions, templates, examples)
3. Establishes clear separation: agents = orchestration, skills = knowledge

Current agent sizes:
- `story-writer.md` - 206 lines (template-heavy)
- `terms-writer.md` - 148 lines
- `spec-writer.md` - 142 lines
- `performance-analyst.md` - 75 lines
- `changelog-writer.md` - 67 lines
- `pr-creator.md` - 60 lines

## Key Files

- `plugins/core/agents/*.md` - All 6 agent files to be thinned
- `plugins/core/skills/*/SKILL.md` - Existing and new skills to receive extracted content

## Related History

Past tickets that touched similar areas:

- `20260127020640-extract-changelog-skill.md` - Extracted changelog generation to skill (same pattern)
- `20260127021000-extract-story-skill.md` - Extracted story metrics to skill (same pattern)
- `20260127021013-extract-spec-skill.md` - Extracted spec context to skill (same pattern)
- `20260127021024-extract-pr-skill.md` - Extracted PR operations to skill (same pattern)

## Implementation Steps

### 1. Create `write-story` skill

Extract from `story-writer.md`:
- Story content structure template (sections 1-7)
- Flowchart guidelines
- Changes guidelines
- Writing guidelines
- All the markdown template examples

Create `plugins/core/skills/write-story/SKILL.md` containing these instructions.

### 2. Create `write-spec` skill

Extract from `spec-writer.md`:
- Directory structure table
- Frontmatter format
- Content style guidelines
- Cross-cutting concerns analysis
- Critical rules section

Create `plugins/core/skills/write-spec/SKILL.md` containing these instructions.

### 3. Create `write-terms` skill

Extract from `terms-writer.md`:
- Term categories table
- Term entry format template
- Frontmatter format
- Critical rules section

Create `plugins/core/skills/write-terms/SKILL.md` containing these instructions.

### 4. Create `analyze-performance` skill

Extract from `performance-analyst.md`:
- Evaluation framework (5 dimensions)
- Output format template
- Guidelines for fair evaluation

Create `plugins/core/skills/analyze-performance/SKILL.md` containing these instructions.

### 5. Thin down all agents

Update each agent file to follow this pattern:

```yaml
---
name: <agent-name>
description: <when to use this agent>
tools: <tool list>
skills:
  - <primary-skill>
  - <supporting-skills...>
---

# <Agent Name>

<One paragraph describing the agent's purpose and what it produces.>

## Input

<What the agent receives when invoked.>

## Output

<What the agent returns when complete.>
```

Target: ~20-30 lines per agent.

### 6. Reorganize existing skills

Some existing skills have verb-noun naming that doesn't match the new pattern:
- `gather-spec-context` → keep as-is (utility skill)
- `gather-terms-context` → keep as-is (utility skill)
- `calculate-story-metrics` → keep as-is (utility skill)
- `generate-changelog` → merge into `write-changelog` skill
- `manage-pr` → merge into `create-pr` skill

### 7. Update skill preloading

Ensure all agents preload their relevant skills:

| Agent               | Primary Skill        | Supporting Skills                          |
| ------------------- | -------------------- | ------------------------------------------ |
| story-writer        | write-story          | calculate-story-metrics                    |
| spec-writer         | write-spec           | gather-spec-context, enforce-i18n          |
| terms-writer        | write-terms          | gather-terms-context, enforce-i18n         |
| changelog-writer    | write-changelog      | (none)                                     |
| pr-creator          | create-pr            | (none)                                     |
| performance-analyst | analyze-performance  | (none)                                     |

## Considerations

- Skills are injected into subagent context at startup, not called on-demand
- Keep shell scripts in existing utility skills (`calculate-story-metrics`, `gather-*-context`)
- The new "write-*" skills contain prose instructions and templates, no scripts
- Agents become declarative configurations that wire skills together
- This matches Claude Code's documented pattern for subagent skill preloading
