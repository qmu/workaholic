---
name: rule-advisor
description: Propose .claude/rules/ directory with TypeScript coding conventions. Use when user wants to enforce coding standards.
---

# Rule Advisor

Analyze the user's TypeScript project and propose coding convention rules for their `.claude/rules/` directory.

## When to Activate

- User wants to enforce coding standards
- User asks about TypeScript conventions for Claude Code
- Workaholic command proposes rule installation

## Instructions

1. Check if user already has rules in `.claude/rules/`
2. Analyze project conventions:
   - tsconfig.json settings (strict mode, target)
   - ESLint/Biome config if present
   - Existing code patterns
3. Read templates from `references/` directory
4. Propose rules based on project analysis
5. Ask user which rules they want
6. Create rule files in `.claude/rules/`

## Reference Templates

- `references/typescript-conventions.md` - Core TypeScript coding standards

## Rule Categories

### 1. Import Patterns

- Use path aliases instead of relative imports (`../`)
- Only use `./` for same-directory imports

### 2. Type Safety

- Avoid `any` - use `unknown` as first option
- Avoid `as` type assertions - prefer type guards and narrowing
- Use `type` over `interface`
- Use `undefined` over `null`

### 3. Code Hygiene

- Inline single-use types in function signatures
- Avoid unnecessary optionals (`?`) without concrete reason
- Avoid unused underscore-prefixed arguments (`_arg`)
- Delete dead code immediately - grep for usage before editing

## Example Flow

```
User: "I want coding rules for my TypeScript project"

Advisor:
1. Check .claude/rules/ - no rules found
2. Check tsconfig.json - strict mode enabled
3. Check eslint config - airbnb style

Propose:
"I'll create TypeScript coding rules for your project. Based on your setup:
- Strict TypeScript enabled
- ESLint with Airbnb style

Recommended rules:
1. typescript-conventions.md - Core TS patterns

Want me to create these rules? Any customizations?"
```

## Customization Questions

Ask user about:

1. **Path aliases**: What path aliases does the project use? (check tsconfig.json)
2. **Null vs undefined**: Does the project have existing null usage to maintain?
3. **Additional rules**: Any project-specific conventions to add?
