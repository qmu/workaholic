---
name: commit
description: Commit all changes (staged and unstaged) in logical units. ONLY commit when the developer explicitly asks.
---

# Commit

Commit pending changes by grouping them into logical units.

## CRITICAL RULES

- **NEVER amend** existing commits without explicit instruction
- If developer says "revert" or cancels, do NOT commit the reverted state

## Instructions

1. Run `git status` to see all staged and unstaged changes
2. Run `git diff` and `git diff --cached` to understand the changes
3. Run `npx prettier --write` on modified files to format before committing
4. Analyze and group changes into logical commit units:
   - Related changes belong in the same commit
   - Unrelated changes should be split into separate commits
   - Each commit represents a single coherent change
5. For each logical unit:
   - Stage relevant files with `git add`
   - Create a commit with a meaningful message
6. Proceed through all logical units without asking for confirmation

## Commit Message Rules

- **NO prefixes** - Do not use `[feat]`, `[fix]`, `feat:`, `fix:`, etc.
- Start with a present-tense verb (Add, Update, Fix, Remove, Refactor)
- Focus on **WHY** the change was made, not just what changed
- Keep the title concise (50 characters or less)
- Use body for additional context if needed

## Examples

```
Add JSDoc comments to gateway exports for documentation
Update traceparent format with W3C spec explanation
Fix session decryption to handle invalid tokens gracefully
Remove unused RegisterTool type after consolidation
```
