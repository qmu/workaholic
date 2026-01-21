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

**ONLY suggest topics defined in `workaholic-advisor/SKILL.md`.**

1. Read `workaholic-advisor/SKILL.md` to get the **exact** list of topics from the table
2. **NEVER invent or suggest topics not in the table** (no testing.md, git-workflow.md, etc.)
3. For each topic in the table, check if the target path exists
4. Every MISSING item MUST be added - no exceptions

## Phase 1: Discovery

Launch the **discover-claude-dir** agent to explore:

- `.claude/` directory configuration
- Existing `CLAUDE.md` content
- `package.json`, `Cargo.toml`, `go.mod` for tech stack

Read `workaholic-advisor/SKILL.md` to get the list of all topics and templates.

## Phase 2: Validation

For each topic **in the SKILL.md table only** (do NOT invent new topics):

1. Read the topic file to understand what it provides
2. Read the template(s) to know required features
3. Check user's project:
   - Does the file exist?
   - Does it have all features from the template? (e.g., icebox support)
4. Mark status:
   - ✅ found - exists with all features
   - 🔄 outdated - exists but missing features from template
   - 🔄 legacy - exists but needs rename
   - ⏭️ not needed - condition not met
   - ❌ MISSING - must be added

## Phase 3: Proposal

Output status for every topic checked:

```
## Current State

[For each topic from workaholic-advisor, show status]

## Will Update

[List ALL items marked ❌ MISSING, 🔄 outdated, or 🔄 legacy]
```

**Rule**: Every ❌ MISSING, 🔄 outdated, and 🔄 legacy item MUST appear in "Will Update".

## Phase 4: Execute Updates

For each item in "Will Update":

1. Read the topic and template(s) from `workaholic-advisor`
2. For ❌ MISSING: create from template
3. For 🔄 outdated: update file to include missing features from template
4. For 🔄 legacy: rename to correct path
5. Report what was changed

**Do not skip items. Do not ask - just update them.**

## Important

- **ONLY** use topics from the `workaholic-advisor/SKILL.md` table
- **NEVER** suggest files not in the table (e.g., testing.md, git-workflow.md, settings.json)
- If a topic's condition is not met, mark it ⏭️ not needed - do not invent alternatives
