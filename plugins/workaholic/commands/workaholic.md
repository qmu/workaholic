---
name: workaholic
description: Analyze .claude configuration and update it to follow best practices.
---

# Workaholic

Analyze `.claude/` configuration and update it to follow best practices.

## Scope

This command **only updates**:

- `.claude/` directory (commands, skills, rules)
- `CLAUDE.md` file (add missing sections only)

## Core Rule

**Apply all knowledge from `workaholic-advisor` skill.**

1. Read `workaholic-advisor/SKILL.md` to discover all available topics
2. For each topic, check if the corresponding item exists in the user's project
3. Every MISSING item MUST be added - no exceptions

## Phase 1: Discovery

Launch the **discover-claude-dir** agent to explore:

- `.claude/` directory configuration
- Existing `CLAUDE.md` content
- `package.json`, `Cargo.toml`, `go.mod` for tech stack

Read `workaholic-advisor/SKILL.md` to get the list of all topics and templates.

## Phase 2: Validation

For each topic in `workaholic-advisor`:

1. Read the topic file to understand what it provides and when it applies
2. Check if the item exists in the user's project
3. Mark status:
   - ✅ found - exists and correct
   - 🔄 legacy - exists but needs rename/update
   - ⏭️ not needed - condition not met (e.g., TypeScript rules for non-TS project)
   - ❌ MISSING - must be added

## Phase 3: Proposal

Output status for every topic checked:

```
## Current State

[For each topic from workaholic-advisor, show status]

## Will Add

[List ALL items marked ❌ MISSING or 🔄 legacy]
```

**Rule**: Every ❌ MISSING and 🔄 legacy item MUST appear in "Will Add".

## Phase 4: Execute Updates

For each item in "Will Add":

1. Read the topic from `workaholic-advisor` for guidance
2. Read the template(s) from `workaholic-advisor` for content
3. Create the file/directory in the user's project
4. Report what was created

**Do not skip items. Do not ask if user wants to add MISSING items - add them.**
