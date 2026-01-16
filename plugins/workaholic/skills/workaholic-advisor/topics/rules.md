# TypeScript Rules

Best practices for `.claude/rules/typescript.md` with TypeScript coding conventions.

## When to Propose

- TypeScript project with no rules in `.claude/rules/`
- User wants to enforce coding standards

## Analysis Steps

1. Check `.claude/rules/` for existing rules
2. Review tsconfig.json (strict mode, paths)
3. Check ESLint/Biome config if present
4. Analyze existing code patterns
5. Determine appropriate `paths` globs for the project

## Customization Questions

| Question         | Options                        | Default   |
| ---------------- | ------------------------------ | --------- |
| Path aliases     | project-specific from tsconfig | detect    |
| Null policy      | undefined only, allow null     | undefined |
| Interface policy | type only, allow interface     | type only |

## Template

See `../templates/typescript-conventions.md`
