---
name: commit-advisor
description: Propose a better /commit command for the user's project. Use when user wants to improve their commit workflow in Claude Code.
---

# Commit Advisor

Analyze the user's project and propose a customized `/commit` command for their `.claude/` directory.

## When to Activate

- User wants to improve their commit workflow
- User asks about commit best practices for Claude Code
- Workaholic command proposes command installation

## Instructions

1. Check if user already has a commit command in `.claude/commands/`
2. Analyze project conventions (existing commit messages, prettier config, etc.)
3. Read the template from `references/commit-command-template.md`
4. Propose a customized commit command based on the template
5. Ask user if they want to customize any rules
6. Create the command in `.claude/commands/commit.md`

## Reference Template

See `references/commit-command-template.md` for the recommended starting point.

## Customization Questions

Ask user about:

1. **Formatter**: Use prettier, eslint --fix, or skip formatting?
2. **Commit prefixes**: Use conventional commits (feat:, fix:) or plain verbs?
3. **Spec workflow**: Does project use doc/specs/ pattern?
4. **Co-author**: Add Co-Authored-By line automatically?

## Example Flow

```
User: "I want a better commit workflow"

Advisor:
1. Check .claude/commands/ - no commit command found
2. Check git log - sees "feat:" prefixes used
3. Check package.json - prettier found

Propose:
"I'll create a /commit command for your project. Based on your setup:
- Prettier formatting enabled
- Conventional commit prefixes (feat:, fix:)
- No spec workflow

Want me to create this command? Any customizations?"
```
