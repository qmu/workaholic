---
name: workaholic
description: Analyze .claude configuration and update it to follow best practices.
---

# Workaholic

Analyze `.claude/` configuration and update it to follow best practices.

## Scope

This command **only updates**:

- `.claude/` directory (commands, settings, rules)
- `CLAUDE.md` file (add missing sections only)

## Principle

**Add missing items, never overwrite existing content.**

## Phase 1: Discovery

Launch the **discover-claude-dir** agent to explore:

- `.claude/` directory configuration
- Existing `CLAUDE.md` content
- `package.json`, `Cargo.toml`, `go.mod` for tech stack

## Phase 2: Validation

Check for missing or incomplete items using this checklist:

### CLAUDE.md Checklist

| Section          | Required | Check                                    |
| ---------------- | -------- | ---------------------------------------- |
| Written Language | Yes      | Must specify language (English, etc.)    |
| Tech Stack       | Yes      | Must list runtime, language, framework   |
| Project Summary  | Yes      | Must describe what the project does      |
| Setup            | No       | Installation and run instructions        |
| Commands         | No       | Table of available commands if any exist |

### .claude/ Checklist

| Item                 | Check                                         |
| -------------------- | --------------------------------------------- |
| /commit command      | Exists and follows best practices             |
| /pull-request        | Exists and follows best practices             |
| /ticket command      | Exists (or legacy /spec to rename)            |
| /drive command       | Exists (or legacy /impl-spec to rename)       |
| General rules        | .claude/rules/general.md exists               |
| TypeScript rules     | .claude/rules/typescript.md if TS project     |

### Legacy Detection

| Legacy Name  | New Name  | Action                         |
| ------------ | --------- | ------------------------------ |
| `/spec`      | `/ticket` | Rename spec.md → ticket.md     |
| `/impl-spec` | `/drive`  | Rename impl-spec.md → drive.md |

## Phase 3: Proposal

Output what's found and what will be added:

```
## Current State

### CLAUDE.md
- Written Language: [found / MISSING]
- Tech Stack: [found / MISSING]
- Project Summary: [found / MISSING]
- Commands: [found / not needed / MISSING]

### .claude/
- /commit: [found / MISSING]
- /pull-request: [found / MISSING]
- /ticket: [found / legacy /spec / MISSING]
- /drive: [found / legacy /impl-spec / MISSING]
- General rules: [found / MISSING]
- TypeScript rules: [found / not needed / MISSING]

## Will Add

- [item]: [what will be added]
```

**Important**: If CLAUDE.md has existing command descriptions, do NOT propose changing them.

## Phase 4: Execute Updates

For each item in "Will Add":

1. **Present**: Explain what will be added
2. **Execute**: Add the missing item
3. **Report**: Show what was done
4. **Continue**: Move to next item

User can interrupt at any time.

## Advisor Reference

Read `workaholic-advisor` skill for templates:

| Topic                    | Use For                               |
| ------------------------ | ------------------------------------- |
| `topics/commit.md`       | /commit command                       |
| `topics/pull-request.md` | /pull-request command                 |
| `topics/tdd.md`          | /ticket and /drive commands           |
| `topics/general.md`      | .claude/rules/general.md              |
| `topics/rules.md`        | .claude/rules/ TypeScript conventions |
| `topics/claude-md.md`    | CLAUDE.md missing sections            |

