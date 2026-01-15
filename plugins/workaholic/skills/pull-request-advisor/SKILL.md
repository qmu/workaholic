---
name: pull-request-advisor
description: Propose a better /pull-request command for the user's project. Use when user wants to improve their PR workflow in Claude Code.
---

# Pull Request Advisor

Analyze the user's project and propose a customized `/pull-request` command for their `.claude/` directory.

## When to Activate

- User wants to improve their PR workflow
- User asks about PR best practices for Claude Code
- Workaholic command proposes command installation

## Instructions

1. Check if user already has a pull-request command in `.claude/commands/`
2. Analyze project conventions (branch naming, CHANGELOG usage, etc.)
3. Read the template from `references/pull-request-command-template.md`
4. Propose a customized pull-request command based on the template
5. Ask user if they want to customize any rules
6. Create the command in `.claude/commands/pull-request.md`

## Reference Template

See `references/pull-request-command-template.md` for the recommended starting point.

## Customization Questions

Ask user about:

1. **Branch naming**: What pattern? (e.g., `i<issue>-<date>-<time>`, `feature/<name>`)
2. **CHANGELOG**: Does project use CHANGELOG.md? Where?
3. **PR format**: Three sections (Summary, Changes, Notes) or different?
4. **Issue linking**: How to derive issue URL from branch?

## Example Flow

```
User: "I want a better PR workflow"

Advisor:
1. Check .claude/commands/ - no pull-request command found
2. Check git log - sees branch naming pattern
3. Check root - CHANGELOG.md exists

Propose:
"I'll create a /pull-request command for your project. Based on your setup:
- Branch pattern: feature/<name>
- CHANGELOG integration enabled
- Standard 3-section format

Want me to create this command? Any customizations?"
```
