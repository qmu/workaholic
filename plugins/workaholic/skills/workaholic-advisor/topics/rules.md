# TypeScript Rules

Best practices for `.claude/rules/` with TypeScript coding conventions.

## When to Propose

- TypeScript project with no rules in `.claude/rules/`
- User wants to enforce coding standards

## Analysis Steps

1. Check `.claude/rules/` for existing rules
2. Review tsconfig.json (strict mode, paths)
3. Check ESLint/Biome config if present
4. Analyze existing code patterns

## Rule Categories

### Import Patterns

- Use path aliases instead of `../` relative imports
- Only use `./` for same-directory imports

### Type Safety

- Avoid `any` - use `unknown` as first option
- Avoid `as` assertions - prefer type guards
- Use `type` over `interface`
- Use `undefined` over `null`

### Code Hygiene

- Inline single-use types in function signatures
- Avoid unnecessary optionals without reason
- Delete dead code immediately

## Customization Questions

| Question | Options | Default |
|----------|---------|---------|
| Path aliases | project-specific from tsconfig | detect |
| Null policy | undefined only, allow null | undefined |
| Interface policy | type only, allow interface | type only |

## Template

See `../templates/typescript-conventions.md`
