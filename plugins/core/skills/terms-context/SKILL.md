---
name: terms-context
description: Gather context for terms updates (branch info, tickets, existing terms, diff).
allowed-tools: Bash
user-invocable: false
---

# Terms Context

Gather context needed for updating terminology documentation.

## When to Use

Use this skill to collect information about what changed in the branch and what terms currently exist. This provides the data needed to identify terminology updates.

## Instructions

Run the bundled script to gather context:

```bash
bash .claude/skills/terms-context/sh/gather.sh [base-branch]
```

Default base branch is `main`.

### Output Sections

The script outputs structured information in sections:

```
=== BRANCH ===
<current branch name>

=== TICKETS ===
<list of archived tickets for this branch, or "No archived tickets">

=== TERMS ===
<list of existing term files>

=== DIFF ===
<git diff stat against base branch>

=== COMMIT ===
<current short commit hash>
```

### Using the Output

- **BRANCH**: Use to locate archived tickets
- **TICKETS**: Read these to understand what changed and what new terms may exist
- **TERMS**: Survey these to find documents needing updates
- **DIFF**: Use when no tickets exist to understand changes
- **COMMIT**: Use in frontmatter `commit_hash` field
