---
name: workaholic
description: Analyze .claude configuration and update it to follow best practices.
---

# Workaholic

Analyze `.claude/` configuration and update it to follow best practices.

## Scope

This command **only updates**:

- `.claude/` directory (commands, settings, rules)
- `CLAUDE.md` file

## Phase 1: Discovery

Launch the **discover-claude-dir** agent using the Task tool to explore the `.claude/` directory configuration.

## Phase 2: Analyze and Output Proposal

Based on discovery results, analyze what's missing or could be improved.

### Legacy Command Detection

Check for legacy command names that should be renamed:

| Legacy Name  | New Name  | Action                         |
| ------------ | --------- | ------------------------------ |
| `/spec`      | `/ticket` | Rename spec.md → ticket.md     |
| `/impl-spec` | `/drive`  | Rename impl-spec.md → drive.md |

If legacy commands are found, propose renaming them.

### Advisor Skills

Use as reference knowledge:

- `commit-advisor` - Best practices for /commit command
- `pull-request-advisor` - Best practices for /pull-request command
- `tdd-advisor` - Best practices for /ticket and /drive commands
- `rule-advisor` - Best practices for .claude/rules/ with TypeScript conventions
- `claude-md-advisor` - Best practices for CLAUDE.md structure

Output the proposal:

```
## Proposal

### Already Configured
- [item]: [status]

### Will Update
- [item]: [what will be changed]
```

## Phase 3: Propose and Execute Updates One by One

For each item in the "Will Update" section, propose and execute sequentially:

1. **Present the update**: Explain what will be changed and why
2. **Execute immediately**: Apply the update without asking for confirmation
3. **Report result**: Show what was done
4. **Move to next**: Proceed to the next update

This approach allows the user to interrupt at any time if they don't want to continue.

### If user interrupts

Stop immediately and report what has been completed so far.

## Update Procedures Reference

For each update type, follow these procedures:

### Rename Legacy Commands

If renaming legacy commands:

1. **Rename /spec → /ticket**: `mv .claude/commands/spec.md .claude/commands/ticket.md`, update name in frontmatter
2. **Rename /impl-spec → /drive**: `mv .claude/commands/impl-spec.md .claude/commands/drive.md`, update name in frontmatter

### Create/Update Commands

1. **/commit command**: Read `commit-advisor` skill, then create/update `.claude/commands/commit.md`
2. **/pull-request command**: Read `pull-request-advisor` skill, then create/update `.claude/commands/pull-request.md`
3. **/ticket command**: Read `tdd-advisor` skill, then create/update `.claude/commands/ticket.md`
4. **/drive command**: Read `tdd-advisor` skill, then create/update `.claude/commands/drive.md`

### Create/Update Rules

5. **TypeScript conventions**: Read `rule-advisor` skill, then create `.claude/rules/typescript-conventions.md`

### Other Updates

6. **CLAUDE.md**: Read `claude-md-advisor` skill, then create/update `CLAUDE.md`
7. **settings.json**: Create/update `.claude/settings.json`

## Example Flow

### Example: Rename legacy commands

```
[Phase 1: discover-claude-dir agent]

## Current State
- Has /spec command (legacy)
- Has /impl-spec command (legacy)
- Has /commit, /pull-request commands

[Phase 2: Output proposal]

## Proposal

### Already Configured
- /commit command: Well configured
- /pull-request command: Well configured

### Will Update
- Rename /spec → /ticket
- Rename /impl-spec → /drive
- Update CLAUDE.md

[Phase 3: Propose and execute one by one]

### 1. Rename /spec → /ticket

The /spec command uses a legacy name. Renaming to /ticket for consistency.

Renaming .claude/commands/spec.md → ticket.md... Done.

### 2. Rename /impl-spec → /drive

The /impl-spec command uses a legacy name. Renaming to /drive for consistency.

Renaming .claude/commands/impl-spec.md → drive.md... Done.

### 3. Update CLAUDE.md

Updating command table to reflect renamed commands.

Updating CLAUDE.md... Done.

---

All updates complete.
```
