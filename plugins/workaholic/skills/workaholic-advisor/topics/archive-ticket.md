# Archive Ticket Skill

Complete commit workflow - format, archive, update changelog, and commit in one operation.

## Overview

A skill that provides a reusable shell script for the complete commit workflow. The `/drive` command invokes this skill after user approves implementation, handling everything in a single bash call.

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
        └── archive.sh        # Shell script for complete workflow
```

## How It Works

1. User approves implementation in `/drive`
2. `/drive` runs the archive script with ticket path, commit message, and repo URL
3. Script handles everything:
   - Format modified files with prettier
   - Archive ticket to `<ticket-dir>/archive/<branch>/`
   - Create/update branch CHANGELOG
   - Stage all changes and commit
   - Add commit hash to CHANGELOG (via amend)

## Usage

```bash
bash .claude/skills/archive-ticket/scripts/archive.sh \
  <ticket-path> \
  "<commit-message>" \
  <repo-url> \
  [modified-files...]
```

## Template

- `../templates/archive-ticket-skill.md` - SKILL.md content
- `../templates/archive-ticket-script.sh` - Shell script content
