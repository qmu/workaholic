---
title: Coding Standards and Conventions
slug: coding-standards
category: implementation
source: https://qmu.co.jp/implementation/coding-standards
---

# Coding Standards and Conventions

_Define formatting, naming, and style conventions once and enforce them automatically, so code review focuses on logic rather than style._

A codebase without consistent conventions accumulates two costs: the cognitive overhead of context-switching between styles within the same file, and the review noise of style discussions in PRs. Both are avoidable. Formatters and linters enforce conventions automatically, reducing the human cost to the initial choice of tool and configuration. With generative AI as a default author, consistent conventions also constrain the AI's output style, reducing the range of cosmetic variation that requires post-generation cleanup.

## Goal (目標)

The situation this policy aims to achieve is one in which the formatting and naming of any file in the codebase can be predicted from the conventions, rather than inferred from the surrounding context.

- A formatter runs on save and on CI, producing identical output regardless of who wrote the code.
- Naming conventions (for files, exports, types, constants, database columns) are documented and checked where tooling supports it.
- Code review comments on style are not needed — the formatter settled style questions before the PR was opened.

## Responsibility (責務)

The situation this policy aims to prevent is one in which formatting and naming conventions are unenforced, so each contributor brings their own habits and PRs accumulate style noise.

States we do not tolerate:

- A formatter configured but not run in CI, leaving the enforcement optional.
- Naming conventions that differ between the frontend and backend of the same codebase without reason.
- Configuration files (`eslint.config.*`, `.prettierrc`, `golangci-lint.yml`) that have diverged from each other, creating conflicting rules.
- Style discussions in PR comments on code that a formatter would have resolved.

## Practices (実践)

### Use a formatter as the authority on whitespace and syntax style

For TypeScript/JavaScript: Prettier with a committed `.prettierrc`. For Go: `gofmt` and `goimports`. For other languages, adopt the ecosystem's standard formatter. The formatter is run on pre-commit (via a hook or `lint-staged`) and verified in CI. The formatter's output is not overridden by eslint or lint rules; formatting and linting are separate concerns.

### Run linters in CI with all rules enabled

Linters (ESLint, golangci-lint, equivalent) are configured with the project's rule set and run in CI. Rules are not disabled without a comment explaining why and whether the suppression is temporary. The linter configuration file is committed; linter suppressions in source files are tracked.

### Document naming conventions where tooling cannot enforce them

Conventions that tooling cannot yet enforce — database column naming style, file naming patterns, naming conventions for derived types — are documented in a `CONTRIBUTING.md` or an ADR. When a pattern recurs, consider adding a lint rule.

### Related: Preferring Declarative Code, Preferring Rich Typing, Directory Structure Conventions

Coding standards interact with the language-level conventions of [Preferring Declarative Code](functional-programming.md) and [Preferring Rich Typing](type-driven-design.md). The file and directory layout conventions are in [Directory Structure Conventions](directory-structure.md).
