---
name: spec-context
description: Gather context for spec updates (branch info, tickets, existing specs, diff).
allowed-tools: Bash
user-invocable: false
---

# Spec Context

Gather context needed for updating specification documents.

## When to Use

Use this skill to collect information about what changed in the branch and what specs currently exist. This provides the data needed to decide which specs to update.

## Instructions

Run the bundled script to gather context:

```bash
bash .claude/skills/spec-context/sh/gather.sh [base-branch]
```

Default base branch is `main`.

### Output Sections

The script outputs structured information in sections:

```
=== BRANCH ===
<current branch name>

=== TICKETS ===
<list of archived tickets for this branch, or "No archived tickets">

=== SPECS ===
<list of existing spec files>

=== DIFF ===
<git diff stat against base branch>

=== COMMIT ===
<current short commit hash>
```

### Using the Output

- **BRANCH**: Use to locate archived tickets
- **TICKETS**: Read these to understand what changed and why
- **SPECS**: Survey these to find documents needing updates
- **DIFF**: Use when no tickets exist to understand changes
- **COMMIT**: Use in frontmatter `commit_hash` field
