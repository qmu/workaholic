# Branch Command

Best practices for the `/branch` command.

## When to Propose

- Project has no branch command in `.claude/commands/`
- Developer wants a quick way to create feature/fix/refactor branches

## Analysis Steps

1. Check `.claude/commands/` for existing branch command
2. Review `git branch` to see existing branch naming patterns
3. Check if project uses any branch naming conventions

## Customization Questions

| Question         | Options                           | Default           |
| ---------------- | --------------------------------- | ----------------- |
| Branch prefixes  | feat, fix, refact, chore, docs    | feat, fix, refact |
| Timestamp format | YYYYMMDD-HHMMSS, YYYYMMDD, custom | YYYYMMDD-HHMMSS   |
| Auto checkout    | yes, no                           | yes               |

## Template

See `../templates/branch-command.md`
