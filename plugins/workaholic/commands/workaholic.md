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

Use the advisor skills as reference knowledge:
- `commit-advisor` - Best practices for /commit command
- `pull-request-advisor` - Best practices for /pull-request command
- `tdd-advisor` - Best practices for /ticket and /drive commands (spec-driven development)

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

1. **/commit command**: Read `commit-advisor` skill, then create/update `.claude/commands/commit.md`
2. **/pull-request command**: Read `pull-request-advisor` skill, then create/update `.claude/commands/pull-request.md`
3. **/ticket command**: Read `tdd-advisor` skill, then create/update `.claude/commands/ticket.md`
4. **/drive command**: Read `tdd-advisor` skill, then create/update `.claude/commands/drive.md`
5. **CLAUDE.md**: Create/update based on project analysis
6. **settings.json**: Create/update `.claude/settings.json`

## Example Flow

```
[Phase 1: discover-claude-dir agent]

## Current State
- Has /release command
- Missing /commit and /pull-request commands
- settings.json present

[Phase 2: Output proposal]

## Proposal

### Already Configured
- /release command: Working well
- CLAUDE.md: Comprehensive

### Will Update
- /commit command: Create with conventional commits format
- /pull-request command: Create with PR template
- settings.json: Add read-only git commands

[Phase 3: AskUserQuestion dialog]

┌─ Updates ─────────────────────────────────────────┐
│ Which updates do you want to apply?               │
│                                                   │
│ ☑ /commit command                                 │
│   Create with conventional commits format         │
│                                                   │
│ ☑ /pull-request command                           │
│   Create with PR template                         │
│                                                   │
│ ☐ settings.json                                   │
│   Add read-only git commands                      │
└───────────────────────────────────────────────────┘

[User selects /commit and /pull-request]

[Phase 4: Execute selected updates]

Creating .claude/commands/commit.md...
Creating .claude/commands/pull-request.md...

Done.
```
