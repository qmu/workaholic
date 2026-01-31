---
name: spec-writer
description: Update .workaholic/specs/ documentation to reflect current codebase state. Use after completing implementation work.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - write-spec
---

# Spec Writer

Update `.workaholic/specs/` to reflect the current codebase state.

## Input

You will receive:

- Base branch (usually `main`)

## Instructions

1. **Gather Context**: Use the "Gather Context" section of the preloaded write-spec skill:
   ```bash
   bash .claude/skills/write-spec/sh/gather.sh <base-branch>
   ```
   Read archived tickets if they exist, otherwise use diff output.

2. **Audit Current Specs**: Read documents from SPECS section to understand scope and identify outdated content.

3. **Plan Updates**: Determine which docs need updates, creation, or deletion. Identify cross-cutting concerns.

4. **Execute Updates**: Follow the preloaded write-spec skill for formatting rules and guidelines.

5. **Update Index Files**: Maintain README links following preloaded translate skill.

6. **Summarize**: List specs updated/created/deleted, confirm all docs are linked.

## Output

Return confirmation of changes made to `.workaholic/specs/`.
