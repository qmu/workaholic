---
name: archive-ticket
description: Complete commit workflow - format, archive, update changelog, and commit in one operation.
allowed-tools: Bash
user-invocable: false
---

# Archive Ticket

Complete commit workflow after user approves implementation.

## When to Use

Use this skill after user approves implementation. The script handles formatting, archiving, changelog, and commit.

**IMPORTANT**: Always use the script. Never manually move tickets or create changelogs.

**Note**: Archiving requires being on a named branch (not detached HEAD). The script will exit with an error if not on a branch.

## Instructions

Run the bundled script with ticket path, commit message, and repo URL:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh <ticket-path> <commit-message> <repo-url> [files...]
```

Example:

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  doc/tickets/20260115-feature.md \
  "Add new feature" \
  https://github.com/org/repo \
  src/foo.ts src/bar.ts
```

## Commit Message Rules

- **NO prefixes** - Do not use `[feat]`, `[fix]`, `feat:`, `fix:`, etc.
- Start with a present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made, not just what changed
- Keep the title concise (50 characters or less)
- Use body for additional context if needed

### Examples

```
Add JSDoc comments to gateway exports for documentation
Update traceparent format with W3C spec explanation
Fix session decryption to handle invalid tokens gracefully
Remove unused RegisterTool type after consolidation
```

## CHANGELOG Categorization

Entries are automatically categorized based on commit verb:

- **Added**: Add, Create, Implement, Introduce
- **Changed**: Update, Fix, Refactor (default)
- **Removed**: Remove, Delete
