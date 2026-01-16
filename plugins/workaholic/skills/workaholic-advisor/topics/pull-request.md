# Pull Request Command

Best practices for the `/pull-request` command.

## When to Propose

- Project has no pull-request command in `.claude/commands/`
- Existing PR command needs improvement

## Analysis Steps

1. Check `.claude/commands/` for existing PR command
2. Review branch naming conventions
3. Check for CHANGELOG.md usage
4. Check git remote for GitHub/GitLab URL patterns

## Customization Questions

| Question | Options | Default |
|----------|---------|---------|
| Branch naming | `i<issue>-<date>-<time>`, `feature/<name>`, custom | detect from existing |
| CHANGELOG | integrate from branch, none | integrate |
| PR format | Summary/Changes/Notes sections | yes |
| Issue linking | derive from branch name | yes |

## Template

See `../templates/pull-request-command.md`
