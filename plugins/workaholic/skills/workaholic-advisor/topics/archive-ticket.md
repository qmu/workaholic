# Archive Ticket Skill

Best practices for archiving completed tickets using a skill with bundled shell script.

## Overview

A skill that provides a reusable shell script for archiving tickets to branch-specific folders. The `/drive` command can invoke this skill instead of outputting raw bash commands.

## When to Propose

- Project uses `/ticket` and `/drive` workflow
- User has `/drive` command configured
- No archive-ticket skill exists yet

## Skill Structure

```
.claude/skills/
└── archive-ticket/
    ├── SKILL.md              # Skill definition
    └── scripts/
        └── archive.sh        # Shell script for archiving
```

## How It Works

1. `/drive` completes implementation and commits
2. `/drive` invokes archive-ticket skill: `/archive-ticket <ticket-path>`
3. Skill runs `scripts/archive.sh` with the ticket path
4. Script moves ticket to `doc/tickets/archive/<branch>/`

## Customization Questions

| Question | Options | Default |
|----------|---------|---------|
| Archive location | doc/tickets/archive/, .archive/, custom | doc/tickets/archive/ |
| Organize by | branch, date, flat | branch |

## Template

- `../templates/archive-ticket-skill.md` - SKILL.md content
- `../templates/archive-ticket-script.sh` - Shell script content
