# CLAUDE.md Validation

How to validate and update CLAUDE.md files.

## Validation Checklist

| Section          | Required | How to Check                           |
| ---------------- | -------- | -------------------------------------- |
| Written Language | Yes      | Look for "Written Language" heading    |
| Project Summary  | Yes      | Look for description of what it does   |
| Tech Stack       | Yes      | Look for runtime, language, framework  |
| Commands         | If exist | Table with /commit, /ticket, etc.      |
| Setup            | No       | Installation and run instructions      |

## Detection

1. Read existing CLAUDE.md
2. Check each section against the checklist
3. Mark as "found" or "MISSING"

## Adding Missing Sections

**Principle: Add only, never overwrite.**

### Written Language (if missing)

Ask user:
- English
- Japanese
- Other (specify)

Insert after title:

```markdown
## Written Language

All documentation, commit messages, and pull requests should be written in **{language}**.
```

### Tech Stack (if missing)

Detect from:
- `package.json` → Node.js version, dependencies
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pyproject.toml` → Python

Insert section with detected stack.

### Commands (if missing and .claude/commands/ exists)

Read command files from `.claude/commands/` and create table from their frontmatter descriptions.

**Never use generic descriptions like "create github issue" - use actual command descriptions.**

## Example: Missing Language

```
## Current State

### CLAUDE.md
- Written Language: MISSING
- Tech Stack: Node.js 20, TypeScript 5.x, Next.js 14
- Project Summary: found
- Commands: found

## Will Add

- Written Language section (will ask user preference)
```

Execution:

```
Adding Written Language section to CLAUDE.md.

What language should documentation be written in?
[English / Japanese / Other]

User: Japanese

Adding "## Written Language" section after title...
Done.
```

## Template

See `../templates/claude-md.md`
