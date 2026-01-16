# Commit Command

Best practices for the `/commit` command.

## When to Propose

- Project has no commit command in `.claude/commands/`
- Existing commit command needs improvement

## Analysis Steps

1. Check `.claude/commands/` for existing commit command
2. Review `git log` for commit message patterns
3. Check for prettier/eslint in package.json
4. Check if project uses `doc/tickets/` workflow

## Customization Questions

| Question        | Options                                 | Default     |
| --------------- | --------------------------------------- | ----------- |
| Formatter       | prettier, eslint --fix, none            | prettier    |
| Commit prefixes | conventional (feat:, fix:), plain verbs | plain verbs |
| Co-author       | add Co-Authored-By line                 | yes         |

## Template

See `../templates/commit-command.md`
