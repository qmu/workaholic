---
name: workaholic
description: Analyze .claude configuration and update it to follow best practices.
---

# Workaholic

Analyze `.claude/` configuration and update it to follow best practices.

## Scope

This command **only updates**:
- `.claude/` directory (commands, settings)
- `CLAUDE.md` file

## Phase 1: Discovery

Launch the **discover-claude-dir** agent using the Task tool to explore the `.claude/` directory configuration.

## Phase 2: Analyze and Output Proposal

Based on discovery results, analyze what's missing or could be improved.

### Legacy Command Detection

Check for legacy command names that should be renamed:

| Legacy Name | New Name | Action |
|-------------|----------|--------|
| `/spec` | `/ticket` | Rename spec.md → ticket.md |
| `/impl-spec` | `/drive` | Rename impl-spec.md → drive.md |

If legacy commands are found, propose renaming them.

### Advisor Skills

Use as reference knowledge:
- `commit-advisor` - Best practices for /commit command
- `pull-request-advisor` - Best practices for /pull-request command
- `tdd-advisor` - Best practices for /ticket and /drive commands

Output the proposal:

```
## Proposal

### Already Configured
- [item]: [status]

### Will Update
- [item]: [what will be changed]
```

## Phase 3: Get User Approval

After outputting the proposal, call **AskUserQuestion** to let the user select which updates to apply:

```json
{
  "questions": [{
    "question": "Which updates do you want to apply?",
    "header": "Updates",
    "multiSelect": true,
    "options": [
      {"label": "/commit command", "description": "[specific improvement]"},
      {"label": "/pull-request command", "description": "[specific improvement]"},
      {"label": "settings.json", "description": "[specific improvement]"}
    ]
  }]
}
```

Only include items from "Will Update" section as options.

### If AskUserQuestion is denied (dontAsk mode)

Apply ALL recommended updates automatically and output:

```
dontAsk mode: Applying all updates...
```

## Phase 4: Execute Updates

Execute the user-selected updates (or all updates in dontAsk mode).

For each selected item:

### Rename Legacy Commands

If renaming legacy commands:
1. **Rename /spec → /ticket**: `mv .claude/commands/spec.md .claude/commands/ticket.md`, update name in frontmatter
2. **Rename /impl-spec → /drive**: `mv .claude/commands/impl-spec.md .claude/commands/drive.md`, update name in frontmatter

### Create/Update Commands

1. **/commit command**: Read `commit-advisor` skill, then create/update `.claude/commands/commit.md`
2. **/pull-request command**: Read `pull-request-advisor` skill, then create/update `.claude/commands/pull-request.md`
3. **/ticket command**: Read `tdd-advisor` skill, then create/update `.claude/commands/ticket.md`
4. **/drive command**: Read `tdd-advisor` skill, then create/update `.claude/commands/drive.md`

### Other Updates

5. **CLAUDE.md**: Create/update based on project analysis
6. **settings.json**: Create/update `.claude/settings.json`

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

[Phase 3: AskUserQuestion dialog]

┌─ Updates ─────────────────────────────────────────┐
│ Which updates do you want to apply?               │
│                                                   │
│ ☑ Rename /spec → /ticket                          │
│   Rename command to new standard name             │
│                                                   │
│ ☑ Rename /impl-spec → /drive                      │
│   Rename command to new standard name             │
└───────────────────────────────────────────────────┘

[User selects both]

[Phase 4: Execute]

Renaming .claude/commands/spec.md → ticket.md...
Renaming .claude/commands/impl-spec.md → drive.md...

Done.
```
